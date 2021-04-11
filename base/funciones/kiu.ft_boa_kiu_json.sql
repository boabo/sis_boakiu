CREATE OR REPLACE FUNCTION "kiu"."ft_boa_kiu_json" (
    p_administrador integer, p_id_usuario integer, p_tabla character varying, p_transaccion character varying)
    RETURNS character varying AS
$BODY$

/**************************************************************************
 SISTEMA:		devoluciones
 FUNCION: 		decr.ft_liquidacion_ime
 DESCRIPCION:   Funcion que gestiona las operaciones basicas (inserciones, modificaciones, eliminaciones de la tabla 'decr.tliquidacion'
 AUTOR: 		 (admin)
 FECHA:	        17-04-2020 01:54:37
 COMENTARIOS:
***************************************************************************
 HISTORIAL DE MODIFICACIONES:
#ISSUE				FECHA				AUTOR				DESCRIPCION
 #0				17-04-2020 01:54:37								Funcion que gestiona las operaciones basicas (inserciones, modificaciones, eliminaciones de la tabla 'decr.tliquidacion'
 #
 ***************************************************************************/

DECLARE

    v_nro_requerimiento    	integer;
    v_parametros           	record;
    v_id_requerimiento     	integer;
    v_resp		            varchar;
    v_nombre_funcion        text;
    v_mensaje_error         text;
    v_id_liquidacion	integer;
    v_json	varchar;
    v_query varchar;
    v_count integer;
    v_liqui_json json;

    v_filtro_value varchar;
    v_query_value varchar;
    v_tipo_tab_liqui varchar;
    v_ids_liqui int[];
    v_ids_factucom varchar;
    v_administradora varchar;
    v_fecha_ini date;
    v_fecha_fin date;
    v_id_liquidacion_array int[];


BEGIN

    v_nombre_funcion = 'kiu.ft_boa_kiu_json';
    v_parametros = pxp.f_get_record(p_tabla);

    /*********************************
 	#TRANSACCION:  'KIU_GETFAC_JSON_SEL'
 	#DESCRIPCION:	Insercion de registros
 	#AUTOR:		favio figueroa
 	#FECHA:		11-02-2021 19:36:57
	***********************************/

    if(p_transaccion='KIU_GETFAC_JSON_SEL')then

        begin


            WITH t_boleto_asociado as
                (
                    SELECT tbaf.nro_boleto, td.nroaut, tv.nro_factura, tv.nit, tv.nombre_factura, tv.total_venta,
                           tv.fecha, tv.id_usuario_reg
                    FROM vef.tboletos_asociados_fact tbaf
                    inner JOIN vef.tventa tv on tv.id_venta = tbaf.id_venta
                    inner join vef.tdosificacion td on td.id_dosificacion = tv.id_dosificacion
                    where tbaf.estado_reg = 'activo'
                    and tbaf.nro_boleto = '9302404686224'--v_parametros.billete
                    ),
                    v_existencia_fp as (
                        select bolam.id_boleto_amadeus, count(bolfp.id_boleto_amadeus_forma_pago) as count_boleto
                        from obingresos.tboleto_amadeus bolam
                        inner join obingresos.tboleto_amadeus_forma_pago bolfp on bolfp.id_boleto_amadeus = bolam.id_boleto_amadeus
                        where  bolam.nro_boleto = '9302404710184' and bolfp.modificado = 'si'
                        GROUP BY bolam.id_boleto_amadeus
                    ), t_boleto_amadeus_modificado as (
                        select   bolfp.codigo_tarjeta,
                                 bolfp.numero_tarjeta,
                                 mone.codigo_internacional::varchar as moneda,
                                 bolfp.importe,
                                 fp.fop_code::varchar as forma_pago,
                                 mp.name::varchar as nombre_mp
                        from obingresos.tboleto_amadeus bolam
                                 inner JOIN v_existencia_fp vef on vef.id_boleto_amadeus = bolam.id_boleto_amadeus
                                 inner join obingresos.tboleto_amadeus_forma_pago bolfp on bolfp.id_boleto_amadeus = bolam.id_boleto_amadeus
                                 inner join obingresos.tmedio_pago_pw mp on mp.id_medio_pago_pw = bolfp.id_medio_pago
                                 inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
                                 inner join param.tmoneda mone on mone.id_moneda = bolfp.id_moneda
                        where  bolam.nro_boleto = '9302404710184' and vef.count_boleto >= 1
                    )

            SELECT TO_JSON(ROW_TO_JSON(jsonData) :: TEXT) #>> '{}' as json
            into v_json
            from (
                     SELECT
                         (
                             SELECT ARRAY_TO_JSON(ARRAY_AGG(ROW_TO_JSON(boleto_asociado)))
                             FROM
                                 (
                                     SELECT *
                                     FROM t_boleto_asociado
                                 ) boleto_asociado
                         ) as factura_erp,
                         (
                             SELECT ARRAY_TO_JSON(ARRAY_AGG(ROW_TO_JSON(boleto_amadeus_modificado)))
                             FROM
                                 (
                                     SELECT *
                                     FROM t_boleto_amadeus_modificado
                                 ) boleto_amadeus_modificado
                         ) as boleto_amadeus_modificado

                 ) jsonData;



            --Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'json',v_json);
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje',v_json);

            --Devuelve la respuesta
            return v_resp;

        end;


    else

        raise exception 'Transaccion inexistente: %',p_transaccion;

    end if;

EXCEPTION

    WHEN OTHERS THEN
        v_resp='';
        v_resp = pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
        v_resp = pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
        v_resp = pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
        raise exception '%',v_resp;

END;
$BODY$
    LANGUAGE 'plpgsql' VOLATILE
                       COST 100;
ALTER FUNCTION "kiu"."ft_boa_kiu_json"(integer, integer, character varying, character varying) OWNER TO postgres;
