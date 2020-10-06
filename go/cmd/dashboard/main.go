package main

import (
	"crypto/tls"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/go-stomp/stomp"
	"github.com/kelseyhightower/envconfig"
)

const (
	queueName = "buffs"
)

type EnvVars struct {
	MQTLSEnable bool   `default:"false"`
	MQProtocol  string `default:"tcp"`
	MQHost      string `required:"true"`
	MQPort      string `required:"true"`
	MQUsername  string `required:"true"`
	MQPassword  string `required:"true"`
}

func handle(mq *stomp.Conn) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		body, err := ioutil.ReadAll(r.Body)
		if err != nil {
			log.Printf("WARN: failed to read buff data, %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		if err := mq.Send(queueName, "application/json", body); err != nil {
			log.Printf("WARN: failed to send buff data, %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
	})
}

func main() {
	var config EnvVars
	if err := envconfig.Process("", &config); err != nil {
		log.Fatal(err.Error())
	}

	// Init ActiveMQ
	var (
		stompConn *stomp.Conn
		err       error
	)
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

	http.Handle("/buff", handle(stompConn))
	log.Fatal(http.ListenAndServe(":8080", nil))
}
