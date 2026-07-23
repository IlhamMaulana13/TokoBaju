package handler

import (
	"net/http"

	"be-Baju/config"
	"be-Baju/models"
	"be-Baju/routes"
)

var app http.Handler

func init() {
	// Inisialisasi Database, Migrasi, dan Firebase saat fungsi di-load Vercel
	config.ConnectDB()
	config.DB.AutoMigrate(&models.User{}, &models.Product{}, &models.ProductSize{}, &models.Order{}, &models.OrderItem{}, &models.Review{})
	
	if config.DB.Migrator().HasColumn(&models.Product{}, "stock") {
		config.DB.Migrator().DropColumn(&models.Product{}, "stock")
	}
	
	config.ConnectFirebase()

	// Inisialisasi router Gin
	app = routes.SetupRouter()
}

// Handler adalah entry point Vercel Serverless Function
func Handler(w http.ResponseWriter, r *http.Request) {
	app.ServeHTTP(w, r)
}
