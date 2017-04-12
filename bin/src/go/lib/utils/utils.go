package utils

import (
	"fmt"
	"os"
	"os/exec"
	"syscall"
)

func Backtick(parts ...string) string {
	var cmd = command_prep(parts...)
	out, err := cmd.Output()
	if err != nil {
		handleError(err)
	}
	return string(out[:])
}

func BacktickE(parts ...string) (string, error) {
	var cmd = command_prep(parts...)
	out, err := cmd.Output()
	if err != nil {
		return string(out[:]), err
	}
	return string(out[:]), nil
}

func Run(parts ...string) {
	err := RunE(parts...)
	if err != nil {
		handleError(err)
	}
}

func RunE(parts ...string) error {
	var cmd = command_prep(parts...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

func Exec(parts ...string) {
	command := parts[0]

	binary, lookErr := exec.LookPath(command)
	if lookErr != nil {
		handleError(lookErr)
	}

	env := os.Environ()

	execErr := syscall.Exec(binary, parts, env)
	if execErr != nil {
		handleError(execErr)
	}
}

func DebugRun(cmd_parts ...string) {
	fmt.Printf("Running: %v\n", cmd_parts)
	Run(cmd_parts...)
}

func FileExists(filename string) bool {
	var _, err = os.Stat(filename)
	if err != nil {
		return false
	}
	return true
}

func command_prep(parts ...string) *exec.Cmd {
	command := parts[0]
	remaining_parts := parts[1:len(parts)]
	return exec.Command(command, remaining_parts...)
}

func handleError(err error) {
	fmt.Fprintf(os.Stderr, "%s\n", err)

	code := 1

	if msg, ok := err.(*exec.ExitError); ok { // there is error code
		code = msg.Sys().(syscall.WaitStatus).ExitStatus()
	}

	syscall.Exit(code)
}
