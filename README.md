# SportBuff DevOps Tech Test

The tech test is a chance for you to show off your skills and see what tasks
you are likely to perform while working at SportBuff.

**This is an open ended task and we don't expect you to deliver a full solution.**
This task is partly about your implementation, but also about your reasoning
and ability to plan future work.

Please feel free to reach out if you need any help with this task.

## Time-boxing

Three to four hours should be enough to take a good bite out of this task.
**Please do not spend more than 5 hours on this task**, as this would not be
respectful of your time.

Remember this exercise is about more than just the code you deliver.

## The task

The developers have two simple Golang services:
1. Dashboard, for creating questions (or 'Buffs')
2. Server, a service for serving them to users.

These are in essence, very slim versions of the real services we have in-house.

These two Golang applications require deployments of:

- MySQL
- Redis
- ActiveMQ

There is a docker-compose file that is used by the developers to test the application locally

### How to test locally

Start the dependency services with the command
```
$ docker-compose up -d mysql activemq redis-node-0 redis-node-1 redis-node-2 redis-node-3 redis-node-4 redis-node-5 redis-cluster-init
```

Wait for these services to be set up and ready, then start the services by running:

```
$ docker-compose up --build server dashboard
```

Add a new question ('buff') into the system
```
$ curl -X POST -H "Content-Type: application/json" -d '{"question": "who", "answers": ["me","you"]}' localhost:8080/buff -D -
HTTP/1.1 200 OK
Date: Tue, 06 Oct 2020 13:30:15 GMT
Content-Length: 0
```

Verify that the 'buff' was stored in the system and can be served to the user
```
$ curl localhost:8081/buffs -D -
HTTP/1.1 200 OK
Date: Tue, 06 Oct 2020 13:30:34 GMT
Content-Length: 186
Content-Type: text/plain; charset=utf-8

[{"ID":1,"CreatedAt":"2020-10-06T13:30:15.995Z","UpdatedAt":"2020-10-06T13:30:15.995Z","DeletedAt":{"Time":"0001-01-01T00:00:00Z","Valid":false},"question":"who","answers":["me","you"]}]
```

### So what do I do?

We need a 'battle-ready' production deployment of these services.
**You can use any tools and technologies you feel are appropriate** as long as they can meet the following requirements:

- Both of these services need their API endpoints exposed
- All the service's dependencies need to be deployed (MySQL, Redis, ActiveMQ)
- Secrets (such as DB passwords) must be securely managed (bonus points for secrets-as-code solutions)
- Centralised logging (e.g. elasticsearch/kibana)
- Backup & Restore procedures for the DB
- Auto-Scaling & Live monitoring/alerts
- Infrastructure-as-code (preferably terraform)

### What do I deliver

Please submit a git repo containing:

1. Any progress made implementing your solution
..* terraform scrips e.t.c.
2. An extensive `README.md` that explains:
..* What you have done
..* What is still needed
..* How you would implement the missing bits
..* Time estimate in days how long you think each bit would take

**Provide an honest and reasonable time estimation**
Don't be tempted to under-estimate to impress us.
If you got this far, we are already impressed :)
