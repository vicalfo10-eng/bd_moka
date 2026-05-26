DELIMITER $$

CREATE TRIGGER tr_inicializar_saldo_cuota
BEFORE INSERT ON plan_pagos
FOR EACH ROW
BEGIN
    -- Copia automáticamente el monto al saldo inicial
    SET NEW.saldo_cuota = NEW.monto_cuota;
END$$

DELIMITER ;