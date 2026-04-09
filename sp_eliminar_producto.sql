DELIMITER $$

DROP PROCEDURE IF EXISTS sp_eliminar_producto$$

CREATE PROCEDURE sp_eliminar_producto(
    IN p_codigo VARCHAR(50)
)
BEGIN
    DECLARE v_id_productos INT DEFAULT 0;
    DECLARE v_con_ventas INT DEFAULT 0;
    DECLARE v_con_movimientos INT DEFAULT 0;

    -- Manejo de errores SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al intentar eliminar el producto' AS msg, 0 AS ok;
    END;

    START TRANSACTION;

    -- 1. Obtener el ID interno del productos
    SELECT id_producto INTO v_id_productos 
    FROM productos 
    WHERE codigo = p_codigo 
    LIMIT 1;

    -- Verificar si el productos existe
    IF v_id_productos IS NULL OR v_id_productos = 0 THEN
        ROLLBACK;
        SELECT 404 AS status, 'El productos no existe' AS msg, 0 AS ok;
    ELSE
        -- 2. Validar en detalle_ventas
        SELECT COUNT(*) INTO v_con_ventas 
        FROM detalle_ventas 
        WHERE id_producto = v_id_productos;

        -- 3. Validar en movimientos_inventario
        SELECT COUNT(*) INTO v_con_movimientos 
        FROM movimientos_inventario 
        WHERE id_producto = v_id_productos;

        -- 4. Lógica de decisión
        IF v_con_ventas > 0 OR v_con_movimientos > 0 THEN
            ROLLBACK;
            SELECT 400 AS status, 
                   CONCAT('El producto tiene historial en ', 
                          IF(v_con_ventas > 0, 'Ventas ', ''), 
                          IF(v_con_movimientos > 0, 'y Movimientos de Inventario.', '.')) AS msg, 
                   0 AS ok;
        ELSE
            -- 5. Si está limpio, eliminamos
            DELETE FROM productos WHERE codigo = p_codigo;
            
            COMMIT;
            SELECT 200 AS status, 'Producto eliminado exitosamente' AS msg, 1 AS ok;
        END IF;
    END IF;

END$$

DELIMITER ;