package uy.edu.ucu.cafeteria_app.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import uy.edu.ucu.cafeteria_app.model.Order;
import uy.edu.ucu.cafeteria_app.model.OrderItem;
import uy.edu.ucu.cafeteria_app.repository.OrderStorage;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderStorage storage;
    private final ProductService productService;
    private final MeterRegistry meterRegistry;

    public Order create(Order o) {
        // validar productos
        for (OrderItem item : o.getItems()) {
            if (!productService.exists(item.getProductId())) {
                throw new IllegalArgumentException("Product " + item.getProductId() + " not found");
            }
        }

        o.setCreatedAt(Instant.now());
        Order saved = storage.save(o);

        // métrica: orders_total{product="<name>"} += quantity
        for (OrderItem item : o.getItems()) {
            String productName = productService.get(item.getProductId()).getName();
            Counter counter = Counter
                    .builder("orders_total")
                    .tag("product", productName)
                    .description("Total de órdenes por producto")
                    .register(meterRegistry);
            counter.increment(item.getQuantity());
        }
        return saved;
    }

    public List<Order> list() { return storage.findAll(); }
    public Order get(Long id) {
        return storage.findById(id).orElseThrow(() -> new IllegalArgumentException("Order not found"));
    }
}
