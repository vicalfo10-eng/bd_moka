DELIMITER $$

DROP PROCEDURE IF EXISTS sp_actualizar_cliente$$

CREATE PROCEDURE sp_actualizar_cliente(
    IN p_identificacion VARCHAR(50),
    IN p_nombre VARCHAR(150),
    IN p_telefono VARCHAR(20),
    IN p_correo VARCHAR(150),
    IN p_direccion VARCHAR(255),
    IN p_activo TINYINT
)
BEGIN
    DECLARE v_existe_correo INT DEFAULT 0;

    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al actualizar cliente' AS msg, 0 AS ok;
    END;

    START TRANSACTION;

    -- Validar que el nuevo correo no le pertenezca a OTRO cliente
    SELECT COUNT(*) INTO v_existe_correo 
    FROM clientes 
    WHERE correo = p_correo AND identificacion <> p_identificacion;

    IF v_existe_correo > 0 THEN
        ROLLBACK;
        SELECT 400 AS status, 'El correo ya está asignado a otro cliente' AS msg, 0 AS ok;
    ELSE
        -- Realizar la actualización
        UPDATE clientes 
        SET nombre = p_nombre,
            telefono = p_telefono,
            correo = p_correo,
            direccion = p_direccion,
            activo = p_activo
        WHERE identificacion = p_identificacion;

        COMMIT;
        SELECT 200 AS status, 'Cliente actualizado correctamente' AS msg, 1 AS ok;
    END IF;

END$$

DELIMITER ;