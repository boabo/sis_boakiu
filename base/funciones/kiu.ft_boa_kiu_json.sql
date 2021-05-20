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
    v_cadena_cnx varchar;
    v_host varchar;
        v_puerto varchar;
        v_dbname varchar;
    v_cuenta_usu varchar;
    v_pass_usu varchar;
    p_user varchar;
    v_password varchar;
    v_semilla varchar;
    v_id_boleto_anulado integer;
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
            v_host=pxp.f_get_variable_global('sincroniza_ip_facturacion');
            v_puerto=pxp.f_get_variable_global('sincroniza_puerto_facturacion');
            v_dbname=pxp.f_get_variable_global('sincronizar_base_facturacion');

            select usu.cuenta,
                   usu.contrasena
            into
                v_cuenta_usu,
                v_pass_usu
            from segu.tusuario usu
            where usu.id_usuario = p_id_usuario;

            p_user= 'dbkerp_'||v_cuenta_usu;

            v_semilla = pxp.f_get_variable_global('semilla_erp');

            select md5(v_semilla||v_pass_usu) into v_password;
            v_cadena_cnx = 'hostaddr='||v_host||' port='||v_puerto||' dbname='||v_dbname||' user='||p_user||' password='||v_password;





            WITH t_boleto_asociado as
                (
                    SELECT tbaf.nro_boleto, td.nroaut, tv.nro_factura, tv.nit, tv.nombre_factura, tv.total_venta,
                           tv.fecha, tv.id_usuario_reg
                    FROM vef.tboletos_asociados_fact tbaf
                    inner JOIN vef.tventa tv on tv.id_venta = tbaf.id_venta
                    inner join vef.tdosificacion td on td.id_dosificacion = tv.id_dosificacion
                    where tbaf.estado_reg = 'activo'
                    and tbaf.nro_boleto = trim(v_parametros.nro_ticket)
                    ),
                    v_existencia_fp as (
                        select bolam.id_boleto_amadeus, count(bolfp.id_boleto_amadeus_forma_pago) as count_boleto
                        from obingresos.tboleto_amadeus bolam
                        inner join obingresos.tboleto_amadeus_forma_pago bolfp on bolfp.id_boleto_amadeus = bolam.id_boleto_amadeus
                        where  bolam.nro_boleto = trim(v_parametros.nro_ticket) and bolfp.modificado = 'si'
                        GROUP BY bolam.id_boleto_amadeus
                    ), t_boleto_amadeus_modificado as (
                        select   bolfp.codigo_tarjeta,
                                 bolfp.numero_tarjeta,
                                 mone.codigo_internacional::varchar as moneda,
                                 bolfp.importe,
                                 fp.fop_code::varchar as forma_pago,
                                 mp.name::varchar as nombre_mp,
                                 ta.codigo_auxiliar || ' - ' || ta.nombre_auxiliar as cuenta_corriente,
                                 CASE
                                     WHEN ta.id_auxiliar is not null  THEN ta.codigo_auxiliar || ' - ' || ta.nombre_auxiliar
                                     WHEN  bolfp.numero_tarjeta is not null or  bolfp.numero_tarjeta != ''  THEN bolfp.numero_tarjeta
                                     ELSE ''
                                     END as referencia
                        from obingresos.tboleto_amadeus bolam
                                 inner JOIN v_existencia_fp vef on vef.id_boleto_amadeus = bolam.id_boleto_amadeus
                                 inner join obingresos.tboleto_amadeus_forma_pago bolfp on bolfp.id_boleto_amadeus = bolam.id_boleto_amadeus

                                 inner join obingresos.tmedio_pago_pw mp on mp.id_medio_pago_pw = bolfp.id_medio_pago
                                 inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
                                 inner join param.tmoneda mone on mone.id_moneda = bolfp.id_moneda
                        left join conta.tauxiliar ta on ta.id_auxiliar = bolfp.id_auxiliar
                        where  bolam.nro_boleto = trim(v_parametros.nro_ticket) and vef.count_boleto >= 1
                    ),t_factura_libro_ventas as (

                SELECT * FROM dblink(v_cadena_cnx,
                                     'select fac.nro_factura, fac.fecha_factura, fac.nro_autorizacion, fac.estado, fac.importe_otros_no_suj_iva, fac.importe_total_venta
                                      From sfe.tfactura fac
                                      where  fac.nro_factura='''||trim(v_parametros.nro_ticket)||''' '
                                  ) AS d (nro_factura varchar, fecha_factura date, nro_autorizacion varchar, estado varchar, importe_otros_no_suj_iva numeric, importe_total_venta numeric)


            ),t_datos_emision as
                (
                    select tp_cajero.nombre_completo2 as cajero, tp_counter.nombre_completo2 as counter
                    from obingresos.tboleto_amadeus bolam
                    inner join segu.tusuario tu_cajero on tu_cajero.id_usuario = bolam.id_usuario_cajero
                    inner join segu.tusuario_externo tue on tue.usuario_externo = bolam.agente_venta
                    inner join segu.tusuario tu_counter on tu_counter.id_usuario = tue.id_usuario
                    inner join segu.vpersona2 tp_cajero on tp_cajero.id_persona = tu_cajero.id_persona
                    inner join segu.vpersona2 tp_counter on tp_counter.id_persona = tu_counter.id_persona
                    where bolam.nro_boleto = trim(v_parametros.nro_ticket) limit 1
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
                         ) as boleto_amadeus_modificado,
                         (
                             SELECT ARRAY_TO_JSON(ARRAY_AGG(ROW_TO_JSON(factura_libro_ventas)))
                             FROM
                                 (
                                     SELECT *
                                     FROM t_factura_libro_ventas
                                 ) factura_libro_ventas
                         ) as factura_libro_ventas,
                         (
                             SELECT TO_JSON(datos_emision) -- solo json por que devolvera un objeto
                             FROM (
                                      SELECT *
                                      FROM t_datos_emision
                                  ) datos_emision
                         ) AS datos_emision

                 ) jsonData;



            --Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'json',v_json);
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje',v_json);

            --Devuelve la respuesta
            return v_resp;

        end;


    /*********************************
 	#TRANSACCION:  'KIU_GETFAC_JSON_SEL'
 	#DESCRIPCION:	Insercion de registros
 	#AUTOR:		favio figueroa
 	#FECHA:		11-02-2021 19:36:57
	***********************************/

    elsif(p_transaccion='KIU_LOGANU_JSON_IME')then

        begin


            insert into vef.tboleto_anulado(
                estado_reg,
                boleto,
                motivo,
                mensaje_erp,
                mensaje_stage,
                anulado_erp,
                anulado_stage,
                id_usuario_reg,
                fecha_reg,
                id_usuario_ai,
                usuario_ai,
                id_usuario_mod,
                fecha_mod
            ) values(
                        'activo',
                        v_parametros.boleto,
                        v_parametros.motivo,
                        v_parametros.mensaje_erp,
                        v_parametros.mensaje_stage,
                        v_parametros.anulado_erp,
                        v_parametros.anulado_stage,
                        p_id_usuario,
                        now(),
                        v_parametros._id_usuario_ai,
                        v_parametros._nombre_usuario_ai,
                        null,
                        null
                    )RETURNING id_boleto_anulado into v_id_boleto_anulado;


            --Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','boleto anulado insertado en el log');
            v_resp = pxp.f_agrega_clave(v_resp,'id_boleto_anulado',v_id_boleto_anulado::varchar);

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
