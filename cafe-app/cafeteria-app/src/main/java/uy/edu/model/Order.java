package uy.edu.ucu.cafeteria_app.model;

import lombok.*;
import java.time.Instant;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Order {
    private Long id;
    private List<OrderItem> items;
    private Instant createdAt;
}
