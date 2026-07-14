package models

import "time"

type Product struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	Name        string    `gorm:"type:varchar(255);not null" json:"name"`
	Description string    `gorm:"type:text" json:"description"`
	Price       float64   `gorm:"type:decimal(10,2);not null" json:"price"`
	Stock       int       `gorm:"not null" json:"stock"`
	ImageURL    string    `gorm:"type:text" json:"image_url"` // URL gambar dari Firebase Storage
	Category    string    `gorm:"type:varchar(100);default:'Semua';not null" json:"category"`
	Rating      float64   `gorm:"type:decimal(3,1);default:0.0;not null" json:"rating"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
