DELIMITER $$

DROP PROCEDURE IF EXISTS sp_kpi_movimientos_hoy$$

CREATE PROCEDURE sp_kpi_movimientos_hoy()

BEGIN

    DECLARE v_movimientos INT DEFAULT 0;

    SELECT COUNT(*) INTO v_movimientos 
    FROM movimientos_inventario 
    WHERE DATE(fecha_creacion) = CURRENT_DATE();

    -- Siempre devolvemos 200 aunque sea 0, porque es una consulta válida de actividad diaria
    SELECT 
        v_movimientos AS total,
        200 AS status,
        'Consulta de movimientos diarios completada' AS msg,
        1 AS ok;
		
END$$

DELIMITER $$