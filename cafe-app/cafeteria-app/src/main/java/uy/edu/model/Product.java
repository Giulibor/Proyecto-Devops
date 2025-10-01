package uy.edu.ucu.cafeteria_app.model;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Product {
    private Long id;
    private String name;
    private double price;
}
