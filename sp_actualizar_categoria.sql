DELIMITER $$

DROP PROCEDURE IF EXISTS sp_actualizar_categoria$$

CREATE PROCEDURE sp_actualizar_categoria(
    IN p_id_categoria INT,
    IN p_nombre VARCHAR(100),
    IN p_descripcion VARCHAR(255),
    IN p_activo TINYINT
)
BEGIN
    -- Declarar variable para verificar existencia antes de la transacción
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al actualizar la categoría' AS msg, 0 AS ok;
    END;

    -- 1. Verificar existencia fuera o al inicio de la transacción
    SELECT COUNT(*) INTO v_existe
	FROM categorias
	WHERE id_categoria = p_id_categoria;

    IF v_existe = 0 THEN
        -- Si no existe, no abrimos transacción o devolvemos error de inmediato
        SELECT 404 AS status, 'La categoría no existe' AS msg, 0 AS ok;
    ELSE
        START TRANSACTION;

        UPDATE categorias SET
            nombre = p_nombre,
            descripcion = p_descripcion,
            activo = p_activo
        WHERE id_categoria = p_id_categoria;

        COMMIT;
        
        SELECT 200 AS status, 'Categoría actualizada correctamente' AS msg, 1 AS ok;
    END IF;
    
END$$

DELIMITER ;