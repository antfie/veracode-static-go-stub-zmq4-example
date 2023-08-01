package main

import (
	"fmt"
	zmq "github.com/pebbe/zmq4"
)

func main() {
	socket, err := zmq.NewSocket(zmq.SUB)

	if err != nil {
		fmt.Printf("Error: %s", err)
		return
	}

	socket.SetSubscribe("")
	socket.Connect("tcp://127.0.0.1:8888")

	fmt.Printf("%v\n", socket)
}
