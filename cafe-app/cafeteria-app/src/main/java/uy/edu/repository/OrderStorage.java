package uy.edu.ucu.cafeteria_app.repository;

import org.springframework.stereotype.Component;
import uy.edu.ucu.cafeteria_app.model.Order;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Component
public class OrderStorage {
    private final Map<Long, Order> data = new ConcurrentHashMap<>();
    private final AtomicLong seq = new AtomicLong(0);

    public Order save(Order o) {
        if (o.getId() == null) o.setId(seq.incrementAndGet());
        data.put(o.getId(), o);
        return o;
    }

    public Optional<Order> findById(Long id) { return Optional.ofNullable(data.get(id)); }
    public List<Order> findAll() { return new ArrayList<>(data.values()); }
}
