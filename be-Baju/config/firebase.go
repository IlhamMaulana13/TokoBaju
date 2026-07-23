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
	var opt option.ClientOption

	if credJSON := os.Getenv("FIREBASE_CREDENTIALS_JSON"); credJSON != "" {
		opt = option.WithCredentialsJSON([]byte(credJSON))
		log.Println("🔑 Menggunakan FIREBASE_CREDENTIALS_JSON dari environment variable")
	} else {
		credFilePath := os.Getenv("FIREBASE_CREDENTIALS")
		if credFilePath == "" {
			credFilePath = "serviceAccountKey.json"
		}

		if _, err := os.Stat(credFilePath); err == nil {
			opt = option.WithCredentialsFile(credFilePath)
			log.Printf("🔑 Menggunakan file credentials dari path: %s\n", credFilePath)
		} else {
			log.Fatalf("❌ Firebase Credentials tidak ditemukan. Harap atur FIREBASE_CREDENTIALS_JSON atau file credentials di path %s", credFilePath)
		}
	}

	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		log.Fatalf("❌ Gagal inisialisasi Firebase: %v\n", err)
	}

	FirebaseApp = app
	log.Println("✅ Berhasil terhubung ke Firebase SDK!")
}
