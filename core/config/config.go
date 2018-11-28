package config

import (
	"fmt"
	"github.com/spf13/viper"
)

func Initialize() error {
	viper.SetConfigName("config")
	viper.AddConfigPath(".")
	return viper.ReadInConfig()
}

func SayHello() string {
	return fmt.Sprintf("Hello")
}
