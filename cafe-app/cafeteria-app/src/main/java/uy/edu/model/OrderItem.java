package uy.edu.model;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class OrderItem {
    private Long productId;
    private int quantity;
}
