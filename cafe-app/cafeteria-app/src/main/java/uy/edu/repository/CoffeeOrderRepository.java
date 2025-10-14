package uy.edu.ucu.cafeteria_app.repo;

import org.springframework.data.jpa.repository.JpaRepository;
import uy.edu.ucu.cafeteria_app.model.CoffeeOrder;

public interface CoffeeOrderRepository extends JpaRepository<CoffeeOrder, Long> {}
