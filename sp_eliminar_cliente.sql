DELIMITER $$

DROP PROCEDURE IF EXISTS sp_eliminar_cliente$$

CREATE PROCEDURE sp_eliminar_cliente(
    IN p_identificacion VARCHAR(50)
)
BEGIN
    DECLARE v_id_cliente INT DEFAULT 0;
    DECLARE v_cantidad_ventas INT DEFAULT 0;

    -- Manejo de errores SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al intentar eliminar el cliente' AS msg, 0 AS ok;
    END;

    START TRANSACTION;

    -- 1. Obtener el id_cliente interno usando la identificación
    SELECT id_cliente INTO v_id_cliente 
    FROM clientes 
    WHERE identificacion = p_identificacion 
    LIMIT 1;

    -- Verificar si el cliente existe en la tabla clientes
    IF v_id_cliente IS NULL OR v_id_cliente = 0 THEN
        ROLLBACK;
        SELECT 404 AS status, 'El cliente no existe' AS msg, 0 AS ok;
    ELSE
        -- 2. Validar si el id_cliente tiene ventas asociadas
        SELECT COUNT(*) INTO v_cantidad_ventas 
        FROM ventas 
        WHERE id_cliente = v_id_cliente;

        IF v_cantidad_ventas > 0 THEN
            ROLLBACK;
            SELECT 400 AS status, 
                   CONCAT('Cliente tiene ', v_cantidad_ventas, ' venta(s) asociada(s) en el sistema.') AS msg, 
                   0 AS ok;
        ELSE
            -- 3. Si no tiene ventas, procedemos con el borrado físico
            DELETE FROM clientes WHERE id_cliente = v_id_cliente;

            COMMIT;
            SELECT 200 AS status, 'Cliente eliminado exitosamente' AS msg, 1 AS ok;
        END IF;
    END IF;

END$$

DELIMITER ;