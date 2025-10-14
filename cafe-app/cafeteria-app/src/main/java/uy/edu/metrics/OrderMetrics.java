package uy.edu.ucu.cafeteria_app.metrics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class OrderMetrics {

    private final Counter created;
    private final Counter delivered;

    public OrderMetrics(MeterRegistry registry) {
        this.created = Counter.builder("coffee_orders_created_total")
                .description("Total de pedidos creados")
                .register(registry);
        this.delivered = Counter.builder("coffee_orders_delivered_total")
                .description("Total de pedidos entregados")
                .register(registry);
    }

    public void incCreated()   { created.increment(); }
    public void incDelivered() { delivered.increment(); }
}
