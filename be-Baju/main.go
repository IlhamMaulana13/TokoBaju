package main

import (
	"log"
	"os"

	"be-Baju/config"
	"be-Baju/models"
	"be-Baju/routes"

	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Println("⚠️ File .env tidak ditemukan")
	}

	config.ConnectDB()
	config.DB.AutoMigrate(&models.User{}, &models.Product{}, &models.Order{}, &models.OrderItem{})
	
	config.ConnectFirebase()

	// Panggil SetupRouter dari package routes
	r := routes.SetupRouter()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	r.Run(":" + port)
}