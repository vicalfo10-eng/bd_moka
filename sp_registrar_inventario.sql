DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_inventario$$

CREATE PROCEDURE sp_registrar_inventario(
    p_id_producto INT,
	p_id_usuario INT,
    p_tipo VARCHAR(10), -- 'ENTRADA' o 'SALIDA'
    p_cantidad INT,
    p_descripcion TEXT
)

BEGIN

    -- Manejo de error SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al registrar el inventario' AS msg;
    END;

    START TRANSACTION;
	
    -- 1. Registrar el movimiento en el historial
    INSERT INTO movimientos_inventario (
		id_producto,
		id_usuario,
		tipo,
		cantidad,
		descripcion,
		fecha_creacion
	)
    VALUES (
		p_id_producto,
		p_id_usuario,
		p_tipo,
		p_cantidad,
		p_descripcion,
		NOW()
	);

    -- 2. Actualizar el stock en la tabla productos
    IF p_tipo = 'ENTRADA' THEN
        UPDATE productos 
        SET stock = stock + p_cantidad 
        WHERE id_producto = p_id_producto;
    ELSEIF p_tipo = 'SALIDA' THEN
        UPDATE productos 
        SET stock = stock - p_cantidad 
        WHERE id_producto = p_id_producto;
        
        -- Opcional: Validar que el stock no sea negativo
        IF (SELECT stock FROM productos WHERE id_producto = p_id_producto) < 0 THEN
		
			ROLLBACK;
			SELECT 400 AS status, 'El stock resultante no puede ser menor a cero.' AS msg;
			
        END IF;
		
    END IF;

    COMMIT;
	
	SELECT 201 AS status, 'Inventario registrado correctamente' AS msg;
	
END$$

DELIMITER ;