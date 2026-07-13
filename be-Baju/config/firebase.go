package config

import (
	"context"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"google.golang.org/api/option"
)

var FirebaseApp *firebase.App

func ConnectFirebase() {
	// Mengambil path file JSON dari .env (FIREBASE_CREDENTIALS=serviceAccountKey.json)
	credFilePath := os.Getenv("FIREBASE_CREDENTIALS")
	if credFilePath == "" {
		log.Fatal("❌ FIREBASE_CREDENTIALS tidak ditemukan di file .env")
	}

	opt := option.WithCredentialsFile(credFilePath)

	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		log.Fatalf("❌ Gagal inisialisasi Firebase: %v\n", err)
	}

	FirebaseApp = app
	log.Println("✅ Berhasil terhubung ke Firebase SDK!")
}
