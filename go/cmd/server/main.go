package main

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/go-stomp/stomp"
	"github.com/kelseyhightower/envconfig"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

const (
	redisKey  = "buffs"
	queueName = "buffs"
)

type EnvVars struct {
	DBName string `required:"true"`
	DBHost string `required:"true"`
	DBPort string `required:"true"`
	DBUser string `required:"true"`
	DBPass string `required:"true"`

	RedisHosts    []string `required:"true"`
	RedisPassword string

	MQTLSEnable bool   `default:"false"`
	MQProtocol  string `default:"tcp"`
	MQHost      string `required:"true"`
	MQPort      string `required:"true"`
	MQUsername  string `required:"true"`
	MQPassword  string `required:"true"`
}

type Buff struct {
	gorm.Model
	Question string           `json:"question"`
	Answers  *json.RawMessage `json:"answers"`
}

func listenNewBuffs(mq *stomp.Conn, db *gorm.DB, rc *redis.ClusterClient) {
	sub, err := mq.Subscribe(queueName, stomp.AckAuto)
	if err != nil {
		log.Fatalf("failed to subscribe for buffs, %v", err)
	}

	for {
		msg, err := sub.Read()
		if err != nil {
			log.Fatalf("error in buff queue, %v", err)
		}
		log.Printf("INFO: new buff '%v'", string(msg.Body))

		var data Buff
		err = json.Unmarshal(msg.Body, &data)
		if err != nil {
			log.Fatalf("failed to unmarshal new buff, %v", err)
		}

		if err := db.Create(&data).Error; err != nil {
			log.Fatalf("failed insert new buff, %v", err)
		}

		if err := rc.Del(context.TODO(), redisKey).Err(); err != nil {
			log.Fatalf("failed to expire old buff, %v", err)
		}
	}
}

func handle(db *gorm.DB, rc *redis.ClusterClient) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		data, err := rc.Get(r.Context(), redisKey).Result()
		if err != nil {
			log.Printf("WARN: failed to get cached redis key %v", err)
		} else {
			// return the response
			w.WriteHeader(http.StatusOK)
			w.Write([]byte(data))
			return
		}

		// Get the data from the DB and marshal it to json
		var buffs []Buff
		db.Find(&buffs)
		j, err := json.Marshal(buffs)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "got error %v", err)
			return
		}

		// Update the value in the redis cache
		if err := rc.Set(r.Context(), redisKey, j, 10*time.Second).Err(); err != nil {
			log.Printf("WARN: failed to update redis key %v", err)
		}

		// return the response
		w.WriteHeader(http.StatusOK)
		w.Write(j)
	})
}

func main() {
	var config EnvVars
	if err := envconfig.Process("", &config); err != nil {
		log.Fatal(err.Error())
	}

	// Init and migrate DB
	dsn := fmt.Sprintf(
		"%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		config.DBUser, config.DBPass, config.DBHost, config.DBPort, config.DBName,
	)
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal(err.Error())
	}
	db.AutoMigrate(&Buff{})
	log.Println("configured database")

	// Init Redis
	rc := redis.NewClusterClient(&redis.ClusterOptions{
		Addrs:    config.RedisHosts,
		Password: config.RedisPassword,
	})
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	if err := rc.Ping(ctx).Err(); err != nil {
		log.Fatal(err.Error())
	}
	log.Println("configured redis")

	http.Handle("/buffs", handle(db, rc))

	go func() {
		log.Fatal(http.ListenAndServe(":8080", nil))
	}()

	// Init ActiveMQ
	var stompConn *stomp.Conn
	mqAddr := config.MQHost + ":" + config.MQPort
	if config.MQTLSEnable {
		conn, err := tls.Dial(config.MQProtocol, mqAddr, &tls.Config{})
		if err != nil {
			log.Fatalf("failed to dial mq %v", err)
		}
		stompConn, err = stomp.Connect(conn,
			stomp.ConnOpt.Login(config.MQUsername, config.MQPassword),
			stomp.ConnOpt.HeartBeat(0, 0),
		)
		if err != nil {
			log.Fatalf("failed to dial mq %v", err)
		}
	} else {
		stompConn, err = stomp.Dial(config.MQProtocol, mqAddr,
			stomp.ConnOpt.HeartBeat(0, 0),
		)
		if err != nil {
			log.Fatalf("failed to dial mq %v", err)
		}
	}

	listenNewBuffs(stompConn, db, rc)
}
