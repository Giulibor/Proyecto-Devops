package uy.edu.ucu.cafeteria_app.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import uy.edu.ucu.cafeteria_app.model.CoffeeOrder;
import uy.edu.ucu.cafeteria_app.model.OrderStatus;
import uy.edu.ucu.cafeteria_app.service.OrderService;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderService svc;

    public OrderController(OrderService svc) {
        this.svc = svc;
    }

    @PostMapping
    public ResponseEntity<CoffeeOrder> create(@RequestBody CoffeeOrder req) {
        return ResponseEntity.ok(svc.create(req));
    }

    @GetMapping
    public List<CoffeeOrder> list() {
        return svc.list();
    }

    @GetMapping("/{id}")
    public CoffeeOrder get(@PathVariable Long id) {
        return svc.get(id);
    }

    @PatchMapping("/{id}/status/{status}")
    public CoffeeOrder updateStatus(@PathVariable Long id, @PathVariable OrderStatus status) {
        return svc.updateStatus(id, status);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        svc.delete(id);
        return ResponseEntity.noContent().build();
    }
}