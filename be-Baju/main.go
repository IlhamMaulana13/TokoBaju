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
		config.DB.AutoMigrate(&models.User{}, &models.Product{}, &models.ProductSize{}, &models.Order{}, &models.OrderItem{}, &models.Review{})
		
		// Drop old stock column if it still exists in products table to prevent HY000 default value errors
		if config.DB.Migrator().HasColumn(&models.Product{}, "stock") {
			log.Println("⚠️ Menghapus kolom 'stock' lama dari tabel products...")
			if err := config.DB.Migrator().DropColumn(&models.Product{}, "stock"); err != nil {
				log.Println("❌ Gagal menghapus kolom 'stock':", err)
			} else {
				log.Println("✅ Kolom 'stock' berhasil dihapus!")
			}
		}
		
		config.ConnectFirebase()

		// Panggil SetupRouter dari package routes
		r := routes.SetupRouter()

		port := os.Getenv("PORT")
		if port == "" {
			port = "8080"
		}
		r.Run(":" + port)
	}