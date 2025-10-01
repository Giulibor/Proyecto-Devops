package uy.edu.ucu.cafeteria_app.model;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class OrderItem {
    private Long productId;
    private int quantity;
}
