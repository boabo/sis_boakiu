CREATE OR REPLACE FUNCTION kiu.ft_boa_kiu_json (
  p_administrador integer,
  p_id_usuario integer,
  p_tabla varchar,
  p_transaccion varchar
)
RETURNS varchar AS
$body$
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

    v_id_boleto_amadeus	integer;
    v_id_forma_pago_amadeus	integer;
    v_contador_id_forma_pago_amadeus	integer;
    v_code_mp	varchar;
    v_codigo_tarjeta		varchar;
    v_res					varchar;
    v_codigo_fp		varchar;

    v_code_mp_2	varchar;
    v_codigo_tarjeta2	varchar;
    v_res2				varchar;
    v_codigo_fp2		varchar;
    v_id_forma_pago_amadeus_2	integer;


    v_id_boleto_fp	integer;
    v_num_tarjeta_2 varchar;
    v_cod_tarjeta_2 varchar;
    nro_tarjeta_2_old varchar;
    nro_autorizacion_2_old varchar;
    v_responsable	varchar;
    v_establecimiento	varchar;

    /*Variables para recorrer el Array de las N formas de Pago*/
    v_id_moneda	integer;
    v_id_forma_pago varchar[];
    v_num_tarjeta varchar[];
    v_cod_tarjeta varchar[];
    v_mco varchar[];
    v_id_auxiliar_anticipo varchar[];
    v_monto_fp numeric;


    v_name_mp	varchar;
    v_codigo_moneda	varchar;
    v_id_usuario_reg	integer;
    v_fecha_reg	 	TIMESTAMP;
    v_id_moneda_fp_1	integer;
    v_id_moneda_fp_2	integer;

    v_codigo_tarjeta_control varchar;
    v_codigo_fp_control		 varchar;

    v_data					 varchar;
    v_datos_recuperar		varchar;
    v_record_json_data_detalle json;
    v_numero_tarjeta		varchar;
    v_id_boleto_amadeus_el	integer;
    v_registros				record;
    v_id_moneda_base		integer;
    v_id_moneda_venta		integer;
    v_monto_total_base		numeric;
    v_fecha_emision			date;
    v_monto_total_boleto	numeric;
    v_cantidad_fp			integer;
    v_acumulado_fp			numeric;
    v_suma_fp_dolar			numeric;
    v_suma_fp_bolivianos	numeric;
    v_suma_total			numeric;
    v_conversion_dolar		numeric;
    v_record_recuperado		record;

    v_total_efectivo_local_original numeric;
    v_total_efectivo_dolar_original numeric;

    v_total_efectivo_dolar_modificado numeric;
    v_total_efectivo_local_modificado numeric;
    v_id_punto_venta_emision	integer;
    v_id_cajero_emision			integer;
    v_estado_apertura_cierre_caja	varchar;
    v_nombre_punto_venta		varchar;
	v_nombre_cajero				varchar;
    v_mon_recibo				varchar;
    v_json_medio_pago_id		varchar;
    v_medio_pago				varchar;
    v_description_mp			varchar;
    v_codigo_medio_pago_mp		varchar;
    v_id_auxiliar 				integer;
    v_id_venta					integer;
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
                     where  bolam.nro_boleto = trim(v_parametros.nro_ticket) --and bolfp.modificado = 'si'
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
                             WHEN  bolfp.numero_tarjeta is not null or  bolfp.numero_tarjeta != ''  THEN bolfp.numero_tarjeta || '/' || bolfp.codigo_tarjeta
                             ELSE ''
                             END as referencia,
                         --Aumentando para el codigo de la forma de pago
                         mp.mop_code
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
                                     'select fac.nro_factura, fac.fecha_factura, fac.nro_autorizacion, fac.estado, fac.importe_otros_no_suj_iva, fac.importe_total_venta, nit_ci_cli, razon_social_cli
                                      From sfe.tfactura fac
                                      where  fac.nro_factura='''||trim(v_parametros.nro_ticket)||''' '
                                  ) AS d (nro_factura varchar, fecha_factura date, nro_autorizacion varchar, estado varchar, importe_otros_no_suj_iva numeric, importe_total_venta numeric, nit_ci_cli varchar, razon_social_cli varchar)


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
                     ), t_formas_pago_erp  as (
                select   bolfp.codigo_tarjeta,
                         bolfp.numero_tarjeta,
                         mone.codigo_internacional::varchar as moneda,
                         bolfp.importe,
                         fp.fop_code::varchar as forma_pago,
                         mp.name::varchar as nombre_mp,
                         ta.codigo_auxiliar || ' - ' || ta.nombre_auxiliar as cuenta_corriente,
                         CASE
                             WHEN ta.id_auxiliar is not null  THEN ta.codigo_auxiliar || ' - ' || ta.nombre_auxiliar
                             WHEN  bolfp.numero_tarjeta is not null or  bolfp.numero_tarjeta != ''  THEN bolfp.numero_tarjeta || '/' || bolfp.codigo_tarjeta
                             ELSE ''
                             END as referencia,
                         --Aumentando para el codigo de la forma de pago
                         mp.mop_code
                from obingresos.tboleto_amadeus bolam
                         inner join obingresos.tboleto_amadeus_forma_pago bolfp on bolfp.id_boleto_amadeus = bolam.id_boleto_amadeus
                         inner join obingresos.tmedio_pago_pw mp on mp.id_medio_pago_pw = bolfp.id_medio_pago
                         inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
                         inner join param.tmoneda mone on mone.id_moneda = bolfp.id_moneda
                         left join conta.tauxiliar ta on ta.id_auxiliar = bolfp.id_auxiliar
                where  bolam.nro_boleto = trim(v_parametros.nro_ticket)
                  and (bolfp.numero_tarjeta != '' and bolfp.numero_tarjeta is not null)
                  and (bolfp.codigo_tarjeta != '' and bolfp.codigo_tarjeta is not null)
            ), t_permiso_transaccion  as (
                select count(*) as permiso
                from segu.trol_procedimiento_gui trpg
                         INNER JOIN segu.tprocedimiento_gui tpg on tpg.id_procedimiento_gui = trpg.id_procedimiento_gui
                         INNER JOIN segu.tprocedimiento tp on tp.id_procedimiento = tpg.id_procedimiento
                         INNER JOIN segu.tusuario_rol tur on tur.id_rol = trpg.id_rol
                where tp.codigo = 'KIU_MOD_TARJE_ERP' and trpg.estado_reg = 'activo' and tur.id_usuario = p_id_usuario
            ), t_nota_debito_credito as (
            	WITH t_liqui as (
                                  SELECT tl.*,
                                         vp.nombre_completo2 as elaborado_por
                                  FROM decr.tliquidacion tl
                                           inner JOIN decr.tliqui_boleto tlb on tlb.id_liquidacion = tl.id_liquidacion
                                           inner join segu.tusuario tu on tu.id_usuario = tl.id_usuario_reg
                                           INNER JOIN segu.vpersona2 vp on vp.id_persona = tu.id_persona
                                  where trim(tlb.data_stage->>'ticketNumber') = trim(v_parametros.nro_ticket) -- aca cambiara el ticket number
                              ),t_nota AS (
                                       SELECT nota.*
                                       FROM decr.tnota nota
                                       inner join t_liqui tl on tl.id_liquidacion::integer = nota.id_liquidacion::integer
                              ), t_factura_pagada AS (
                                  SELECT tv.nro_factura, tl.id_proceso_wf_factura, tv.fecha, tv.total_venta
                                  FROM vef.tventa tv
                                  inner join t_liqui tl on tl.id_proceso_wf_factura::integer = tv.id_proceso_wf::integer
                              ) SELECT tl.id_liquidacion,
                                       tl.nro_liquidacion,
                                       tl.id_proceso_wf_factura,
                                       tl.fecha_liqui,
                                       tl.importe_total,
                                       tl.elaborado_por,
                                       tn.nro_nota,
                                       tn.fecha as fecha_nota,
                                       tn.total_devuelto as importe_nota,
                                       tfp.nro_factura as nro_factura_pagada,
                                       tfp.fecha as fecha_factura_pagada,
                                       tfp.total_venta as total_venta_pagada

                              from t_liqui tl
                              LEFT JOIN t_nota tn on tn.id_liquidacion::integer = tl.id_liquidacion::integer
                              LEFT JOIN t_factura_pagada tfp on tfp.id_proceso_wf_factura = tl.id_proceso_wf_factura
			),t_permiso_transaccion_modificar_formas_pago  as (
                select count(*) as permiso
                from segu.trol_procedimiento_gui trpg
                         INNER JOIN segu.tprocedimiento_gui tpg on tpg.id_procedimiento_gui = trpg.id_procedimiento_gui
                         INNER JOIN segu.tprocedimiento tp on tp.id_procedimiento = tpg.id_procedimiento
                         INNER JOIN segu.tusuario_rol tur on tur.id_rol = trpg.id_rol
                where tp.codigo = 'KIU_MOD_MP_IME' and trpg.estado_reg = 'activo' and tur.id_usuario = p_id_usuario
            ),t_comision_erp as (
                select   COALESCE(bolam.comision,0)::numeric as comision
                from obingresos.tboleto_amadeus bolam
                where  bolam.nro_boleto = trim(v_parametros.nro_ticket))

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
                         ) AS datos_emision,

                         (
                             SELECT ARRAY_TO_JSON(ARRAY_AGG(ROW_TO_JSON(formas_pago_erp_tarjeta))) -- solo json por que devolvera un objeto
                             FROM (
                                      SELECT *
                                      FROM t_formas_pago_erp
                                  ) formas_pago_erp_tarjeta
                         ) AS formas_pago_erp_tarjeta,

                         /*Permisos del ERP*/
                         (
                             SELECT TO_JSON(permiso_modificacion)
                             FROM (
                                      SELECT *
                                      FROM t_permiso_transaccion
                                  ) permiso_modificacion
                         ) AS permiso_modificacion,

                         (
                             SELECT ARRAY_TO_JSON(ARRAY_AGG(ROW_TO_JSON(nota_debito_credito)))
                             FROM (
                                      SELECT *
                                      FROM t_nota_debito_credito
                                  ) nota_debito_credito
                         ) AS nota_debito_credito,

                         (
                             SELECT TO_JSON(permiso_modificacion_medio_pago)
                             FROM (
                                      SELECT *
                                      FROM t_permiso_transaccion_modificar_formas_pago
                                  ) permiso_modificacion_medio_pago
                         ) AS permiso_modificacion_medio_pago,

                         (
                             SELECT TO_JSON(comision_erp)
                             FROM (
                                      SELECT *
                                      FROM t_comision_erp
                                  ) comision_erp
                         ) AS comision_erp

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

        /*********************************
        #TRANSACCION:  'KIU_MOD_TARJE_ERP'
        #DESCRIPCION:	Modificacio de Formas de Pago BOA KIU
        #AUTOR:		Ismael Valdivia
        #FECHA:		14-06-2021 08:30:00
        ***********************************/

    elsif(p_transaccion='KIU_MOD_TARJE_ERP')then

        begin


            select ama.id_boleto_amadeus,
            	   ama.id_usuario_reg,
                   ama.fecha_reg
            into
                v_id_boleto_amadeus,
                v_id_usuario_reg,
                v_fecha_reg
            from obingresos.tboleto_amadeus ama
            where trim(ama.nro_boleto) = trim(v_parametros.boleto_a_modificar)
            and ama.fecha_emision = v_parametros.fecha_emision;

            /*Recuperamos la moneda para la actualizacion*/
            select fp.id_moneda into v_id_moneda_fp_1
            from obingresos.tboleto_amadeus_forma_pago fp
            where trim(fp.codigo_tarjeta) = trim(v_parametros.nro_autorizacion_1_old) and trim(fp.numero_tarjeta) = trim(v_parametros.nro_tarjeta_1_old)
            and fp.id_boleto_amadeus = v_id_boleto_amadeus;
            /*********************************************/

            /*Recuperamos la moneda para la actualizacion*/
            select fp.id_moneda into v_id_moneda_fp_2
            from obingresos.tboleto_amadeus_forma_pago fp
            where trim(fp.codigo_tarjeta) = trim(v_parametros.nro_autorizacion_2_old) and trim(fp.numero_tarjeta) = trim(v_parametros.nro_tarjeta_2_old)
            and fp.id_boleto_amadeus = v_id_boleto_amadeus;
            /*********************************************/

			/*Eliminamos las formas de pago en Tarjeta*/
            delete from obingresos.tboleto_amadeus_forma_pago
            where id_boleto_amadeus = v_id_boleto_amadeus
            and (numero_tarjeta != '' and numero_tarjeta is not null);
            /******************************************/

            select mp.mop_code
            into
                v_code_mp
            from obingresos.tmedio_pago_pw mp
            where mp.id_medio_pago_pw = v_parametros.forma_pago_1::integer;


            /*Validacion de la tarjeta*/
            select mp.mop_code, fp.fop_code into v_codigo_tarjeta, v_codigo_fp
            from obingresos.tmedio_pago_pw mp
                     inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
            where mp.id_medio_pago_pw = v_parametros.forma_pago_1::integer;


            v_codigo_tarjeta = (case when v_codigo_tarjeta is not null then
                                         v_codigo_tarjeta
                                     else
                                         NULL
                end);

            if (v_codigo_tarjeta is not null and v_codigo_fp = 'CC') then
                if (substring(v_parametros.num_tarjeta_1::varchar from 1 for 1) != 'X') then
                    v_res = pxp.f_valida_numero_tarjeta_credito(trim(v_parametros.num_tarjeta_1::varchar),v_codigo_tarjeta);
                end if;
            end if;
            /*********************************************************************/

            /*Insertamos el Registro de la targeta*/
            INSERT INTO obingresos.tboleto_amadeus_forma_pago
            (id_usuario_reg,--1
             fecha_reg,
             id_usuario_mod,
             fecha_mod,
             id_boleto_amadeus,  --2
             importe,--3
             tarjeta,--5
             numero_tarjeta,--6
             codigo_tarjeta,--7
             id_usuario_fp_corregido,--8
             id_medio_pago,--9
             id_moneda,--10
             modificado--11
            )
            VALUES(
                      v_id_usuario_reg,--1
                      v_fecha_reg,
                      p_id_usuario,
                      now(),
                      v_id_boleto_amadeus,--2
                      v_parametros.monto_fp_1::numeric,--3
                      v_code_mp,--5
                      trim(v_parametros.num_tarjeta_1),--6
                      trim(v_parametros.cod_tarjeta_1),--7
                      p_id_usuario,--8
                      v_parametros.forma_pago_1::integer,--9
                      v_id_moneda_fp_1,--10
                      'no'--11
                  );
            /*Aqui Insertamos la segunda Tarjeta*/
            IF  pxp.f_existe_parametro(p_tabla,'forma_pago_2') THEN
                if (v_parametros.forma_pago_2::integer is not null) then

                    select mp.mop_code
                    into
                        v_code_mp_2
                    from obingresos.tmedio_pago_pw mp
                    where mp.id_medio_pago_pw = v_parametros.forma_pago_2::integer;

                    /*Validacion de la tarjeta*/
                    select mp.mop_code, fp.fop_code into v_codigo_tarjeta2, v_codigo_fp2
                    from obingresos.tmedio_pago_pw mp
                             inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
                    where mp.id_medio_pago_pw = v_parametros.forma_pago_2::integer;


                    v_codigo_tarjeta2 = (case when v_codigo_tarjeta2 is not null then
                                                  v_codigo_tarjeta2
                                              else
                                                  NULL
                        end);

                    if (v_codigo_tarjeta2 is not null and v_codigo_fp2 = 'CC') then
                        if (substring(v_parametros.num_tarjeta_2::varchar from 1 for 1) != 'X') then
                            v_res2 = pxp.f_valida_numero_tarjeta_credito(trim(v_parametros.num_tarjeta_2::varchar),v_codigo_tarjeta2);
                        end if;
                    end if;
                    /*********************************************************************/

                    INSERT INTO obingresos.tboleto_amadeus_forma_pago
                    (id_usuario_reg,--1
                     fecha_reg,
                     id_usuario_mod,
                     fecha_mod,
                     id_boleto_amadeus,  --2
                     importe,--3
                     tarjeta,--5
                     numero_tarjeta,--6
                     codigo_tarjeta,--7
                     id_usuario_fp_corregido,--8
                     id_medio_pago,--9
                     id_moneda,--10
                     modificado--11
                    )
                    VALUES(
                              v_id_usuario_reg,--1
                              v_fecha_reg,
                              p_id_usuario,
                              now(),
                              v_id_boleto_amadeus,--2
                              v_parametros.monto_fp_2::numeric,--3
                              v_code_mp_2,--5
                              trim(v_parametros.num_tarjeta_2),--6
                              trim(v_parametros.cod_tarjeta_2),--7
                              p_id_usuario,--8
                              v_parametros.forma_pago_2::integer,--9
                              v_id_moneda_fp_2,--10
                              'no'--11
                          );
                end if;
            end if;

           /* select count (fp.id_boleto_amadeus_forma_pago)
            into
                v_contador_id_forma_pago_amadeus
            from obingresos.tboleto_amadeus_forma_pago fp
            where fp.id_boleto_amadeus = v_id_boleto_amadeus
              and (fp.codigo_tarjeta is not null and fp.codigo_tarjeta != '')
              and (fp.numero_tarjeta is not null and fp.numero_tarjeta != '');

            /*Validacion de la tarjeta*/
            select mp.mop_code, fp.fop_code into v_codigo_tarjeta, v_codigo_fp
            from obingresos.tmedio_pago_pw mp
                     inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
            where mp.id_medio_pago_pw = v_parametros.forma_pago_1::integer;


            v_codigo_tarjeta = (case when v_codigo_tarjeta is not null then
                                         v_codigo_tarjeta
                                     else
                                         NULL
                end);

            if (v_codigo_tarjeta is not null and v_codigo_fp = 'CC') then
                if (substring(v_parametros.num_tarjeta_1::varchar from 1 for 1) != 'X') then
                    v_res = pxp.f_valida_numero_tarjeta_credito(trim(v_parametros.num_tarjeta_1::varchar),v_codigo_tarjeta);
                end if;
            end if;
            /*********************************************************************/


            if (v_contador_id_forma_pago_amadeus = 0) then

                select mp.mop_code
                into
                    v_code_mp
                from obingresos.tmedio_pago_pw mp
                where mp.id_medio_pago_pw = v_parametros.forma_pago_1::integer;



                INSERT INTO obingresos.tboleto_amadeus_forma_pago
                (id_usuario_reg,--1
                 id_boleto_amadeus,  --2
                 importe,--3
                 tarjeta,--5
                 numero_tarjeta,--6
                 codigo_tarjeta,--7
                 id_usuario_fp_corregido,--8
                 id_medio_pago,--9
                 id_moneda,--10
                 modificado--11
                )
                VALUES(
                          p_id_usuario,--1
                          v_id_boleto_amadeus,--2
                          v_parametros.monto_fp_1::numeric,--3
                          v_code_mp,--5
                          trim(v_parametros.num_tarjeta_1),--6
                          trim(v_parametros.cod_tarjeta_1),--7
                          p_id_usuario,--8
                          v_parametros.forma_pago_1::integer,--9
                          1,--10
                          'no'--11
                      );




                IF  pxp.f_existe_parametro(p_tabla,'forma_pago_2') THEN
                    if (v_parametros.forma_pago_2::integer is not null) then

                        select mp.mop_code
                        into
                            v_code_mp_2
                        from obingresos.tmedio_pago_pw mp
                        where mp.id_medio_pago_pw = v_parametros.forma_pago_2::integer;

                        /*Validacion de la tarjeta*/
                        select mp.mop_code, fp.fop_code into v_codigo_tarjeta2, v_codigo_fp2
                        from obingresos.tmedio_pago_pw mp
                                 inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
                        where mp.id_medio_pago_pw = v_parametros.forma_pago_2::integer;


                        v_codigo_tarjeta2 = (case when v_codigo_tarjeta2 is not null then
                                                      v_codigo_tarjeta2
                                                  else
                                                      NULL
                            end);

                        if (v_codigo_tarjeta2 is not null and v_codigo_fp2 = 'CC') then
                            if (substring(v_parametros.num_tarjeta_2::varchar from 1 for 1) != 'X') then
                                v_res2 = pxp.f_valida_numero_tarjeta_credito(trim(v_parametros.num_tarjeta_2::varchar),v_codigo_tarjeta2);
                            end if;
                        end if;
                        /*********************************************************************/



                        INSERT INTO obingresos.tboleto_amadeus_forma_pago
                        (id_usuario_reg,--1
                         id_boleto_amadeus,  --2
                         importe,--3
                         tarjeta,--5
                         numero_tarjeta,--6
                         codigo_tarjeta,--7
                         id_usuario_fp_corregido,--8
                         id_medio_pago,--9
                         id_moneda,--10
                         modificado--11
                        )
                        VALUES(
                                  p_id_usuario,--1
                                  v_id_boleto_amadeus,--2
                                  v_parametros.monto_fp_2::numeric,--3
                                  v_code_mp_2,--5
                                  trim(v_parametros.num_tarjeta_2),--6
                                  trim(v_parametros.cod_tarjeta_2),--7
                                  p_id_usuario,--8
                                  v_parametros.forma_pago_2::integer,--9
                                  1,--10
                                  'no'--11
                              );
                    end if;
                end if;


            else

                select fp.id_boleto_amadeus_forma_pago
                into
                    v_id_forma_pago_amadeus
                from obingresos.tboleto_amadeus_forma_pago fp
                where fp.id_boleto_amadeus = v_id_boleto_amadeus
                  and (fp.codigo_tarjeta is not null and fp.codigo_tarjeta != '')
                  and (fp.numero_tarjeta is not null and fp.numero_tarjeta != '')
                  and fp.importe = v_parametros.monto_fp_1::numeric;


                update obingresos.tboleto_amadeus_forma_pago set
                                                                 numero_tarjeta = trim(v_parametros.num_tarjeta_1),
                                                                 codigo_tarjeta = trim(v_parametros.cod_tarjeta_1),
                                                                 id_usuario_mod = p_id_usuario,
                                                                 fecha_mod = now(),
                                                                 modificado = 'no'
                where id_boleto_amadeus_forma_pago = v_id_forma_pago_amadeus;


                IF  pxp.f_existe_parametro(p_tabla,'forma_pago_2') THEN
                    if (v_parametros.forma_pago_2::integer is not null) then

                        select fp.id_boleto_amadeus_forma_pago
                        into
                            v_id_forma_pago_amadeus_2
                        from obingresos.tboleto_amadeus_forma_pago fp
                        where fp.id_boleto_amadeus = v_id_boleto_amadeus
                          and (fp.codigo_tarjeta is not null and fp.codigo_tarjeta != '')
                          and (fp.numero_tarjeta is not null and fp.numero_tarjeta != '')
                          and fp.importe = v_parametros.monto_fp_2::numeric;


                        update obingresos.tboleto_amadeus_forma_pago set
                                                                         numero_tarjeta = trim(v_parametros.num_tarjeta_2),
                                                                         codigo_tarjeta = trim(v_parametros.cod_tarjeta_2),
                                                                         id_usuario_mod = p_id_usuario,
                                                                         fecha_mod = now(),
                                                                         modificado = 'no'
                        where id_boleto_amadeus_forma_pago = v_id_forma_pago_amadeus_2 and
                                id_boleto_amadeus_forma_pago not in (v_id_forma_pago_amadeus);

                    end if;
                end if;




            end if;*/



            --Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Medio de Pago modificado Correctamente');
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje_exito','Medio de Pago modificado Correctamente en ERP');
            --Devuelve la respuesta
            return v_resp;

        end;

        /*********************************
        #TRANSACCION:  'KIU_GETFAC_JSON_SEL'
        #DESCRIPCION:	KIU_LOGMODI_JSON_IME de registros
        #AUTOR:		Ismael Valdivia
        #FECHA:		16-06-2021 13:58:57
        ***********************************/

    elsif(p_transaccion='KIU_LOGMODI_JSON_IME')then

        begin

            /*Aqui recuperar al funcionario encargado de la modificacion*/
            select usu.desc_persona
            into
                v_responsable
            from segu.vusuario usu
            where usu.id_usuario = p_id_usuario;
            /************************************************************/



            IF  pxp.f_existe_parametro(p_tabla,'forma_pago_2') THEN
                v_num_tarjeta_2 = trim(v_parametros.num_tarjeta_2);
                v_cod_tarjeta_2 = trim(v_parametros.cod_tarjeta_2);
                nro_tarjeta_2_old = v_parametros.nro_tarjeta_2_old;
                nro_autorizacion_2_old = v_parametros.nro_autorizacion_2_old;
            end if;


            insert into obingresos.tlog_modificaciones_medios_pago(
                estado_reg,--1
                nro_boleto,--2
                numero_tarjeta_antiguo,--3
                cod_autorizacion_tarjeta_antiguo,--4
                numero_tarjeta_antiguo_2,--5
                cod_autorizacion_tarjeta_antiguo_2,--6
                numero_tarjeta_modificado,--7
                cod_autorizacion_tarjeta_modificado,--8
                numero_tarjeta_modificado_2,--9
                cod_autorizacion_tarjeta_modificado_2,--10
                observaciones,--11
                id_usuario_reg,--12
                fecha_reg,--13
                id_usuario_ai,--14
                usuario_ai,--15
                id_usuario_mod,--16
                fecha_mod--17
            ) values(
                        'activo',--1
                        v_parametros.nro_boleto,--2
                        v_parametros.nro_tarjeta_1_old,--3
                        v_parametros.nro_autorizacion_1_old,--4
                        nro_tarjeta_2_old,--5
                        nro_autorizacion_2_old,--6
                        trim(v_parametros.num_tarjeta_1),--7
                        trim(v_parametros.cod_tarjeta_1),--8
                        v_num_tarjeta_2,--9
                        v_cod_tarjeta_2,--10
                        v_parametros.observaciones || ' Modificado por: ' || v_responsable,--11
                        p_id_usuario,--12
                        now(),--13
                        v_parametros._id_usuario_ai,--14
                        v_parametros._nombre_usuario_ai,--15
                        null,--16
                        null--17
                    );


            --Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Log registrado correctamente');

            --Devuelve la respuesta
            return v_resp;

        end;

          /*********************************
        #TRANSACCION:  'KIU_NAME_COMER_IME'
        #DESCRIPCION:	Recuperacion de Establecimiento
        #AUTOR:		Ismael Valdivia
        #FECHA:		02-07-2021 12:30:00
        ***********************************/

        elsif(p_transaccion='KIU_NAME_COMER_IME')then

            begin

            	  select est.nombre_estable into v_establecimiento
                  from obingresos.testablecimiento_punto_venta est
                  where est.codigo_estable::integer = v_parametros.nro_comercio::integer;

                   --  raise exception 'Aqui la respuesta %',v_establecimiento;
                 --Definicion de la respuesta
                  v_resp = pxp.f_agrega_clave(v_resp,'mensaje',v_establecimiento);
                  v_resp = pxp.f_agrega_clave(v_resp,'establecimiento',v_establecimiento);

                  --Devuelve la respuesta
                  return v_resp;

            end;

	/*********************************
        #TRANSACCION:  'KIU_MOD_MP_IME'
        #DESCRIPCION:	Modificar Medios de Pago de un Boleto
        #AUTOR:		Ismael Valdivia
        #FECHA:		20-07-2021 11:30:00
        ***********************************/

        elsif(p_transaccion='KIU_MOD_MP_IME')then

            begin

            	/*Aqui recuperamos el Id del Boleto para Eliminar sus formas de pago Actuales*/
                select ama.id_boleto_amadeus,
                	   ama.id_moneda_boleto,
                       ama.fecha_emision,
                       (COALESCE(ama.total,0) - COALESCE(ama.comision,0)),
                       ama.id_punto_venta,
                       ama.id_usuario_cajero
                	   into
                       v_id_boleto_amadeus_el,
                       v_id_moneda_venta,
                       v_fecha_emision,
                       v_monto_total_boleto,
                       v_id_punto_venta_emision,
                       v_id_cajero_emision
                from obingresos.tboleto_amadeus ama
                where ama.nro_boleto = trim(v_parametros.boleto)
                and ama.fecha_emision = v_parametros.fecha_boleto::date;
            	/*****************************************************************************/

                /*Control para no afectar al Cajero*/
                /*Recuperamos el total Cash en dolar para calcular diferencias*/
                select COALESCE(sum(fp.importe),0) into v_total_efectivo_dolar_original
                from obingresos.tboleto_amadeus_forma_pago fp
                inner join obingresos.tmedio_pago_pw mp on mp.id_medio_pago_pw = fp.id_medio_pago
                inner join obingresos.tforma_pago_pw fpw on fpw.id_forma_pago_pw = mp.forma_pago_id
                where fp.id_boleto_amadeus = v_id_boleto_amadeus_el
                and fpw.name = 'CASH' and fp.id_moneda = 2;
				/****************************************************************/

				/*Recuperamos el total Cash en moneda local para calcular diferencias*/
                select COALESCE(sum(fp.importe),0) into v_total_efectivo_local_original
                from obingresos.tboleto_amadeus_forma_pago fp
                inner join obingresos.tmedio_pago_pw mp on mp.id_medio_pago_pw = fp.id_medio_pago
                inner join obingresos.tforma_pago_pw fpw on fpw.id_forma_pago_pw = mp.forma_pago_id
                where fp.id_boleto_amadeus = v_id_boleto_amadeus_el
                and fpw.name = 'CASH' and fp.id_moneda = (select mon.id_moneda
                										  from param.tmoneda mon
                                                          where mon.tipo_moneda = 'base');
                /***********************************************************************/

                /*Recuperamos todas las formas de pago CASH de los modificados para ver si hay variacion*/
                v_total_efectivo_dolar_modificado = 0;
                v_total_efectivo_local_modificado = 0;

                 for i in 1..(v_parametros.cantidad_fp) loop

                	v_data = 'medio_pago_'||i;

                    v_datos_recuperar = v_parametros.json_data :: JSON ->> v_data;

                    FOR  v_record_json_data_detalle IN (SELECT * FROM json_array_elements(v_datos_recuperar :: JSON))

                    loop

                    SELECT mp.name,
                           mp.mop_code,
                           fp.fop_code
                        into
                            v_name_mp,
                            v_codigo_tarjeta_control,
                            v_codigo_fp_control
                    from obingresos.tmedio_pago_pw mp
                    inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
                    where mp.id_medio_pago_pw = (v_record_json_data_detalle->>'id_medio_pago')::integer;

                    IF ((v_record_json_data_detalle->>'monto_fp') = '') THEN
                            raise 'El monto de la forma de pago no puede ser vacio ni cero';
                      END IF;

                    if (v_codigo_tarjeta_control = 'CASH' and ((v_record_json_data_detalle->>'id_moneda')::integer = 2)) then
                        v_total_efectivo_dolar_modificado = (v_total_efectivo_dolar_modificado + (v_record_json_data_detalle->>'monto_fp')::numeric);

                    elsif (v_codigo_tarjeta_control = 'CASH' and ((v_record_json_data_detalle->>'id_moneda')::integer = 1)) then

                        v_total_efectivo_local_modificado = (v_total_efectivo_local_modificado + (v_record_json_data_detalle->>'monto_fp')::numeric);


                    end if;

                    end loop;


                end loop;
                /**********************************************************************/

                /*Verificamos la apertura de caja*/
                select aper.estado
                       into
                       v_estado_apertura_cierre_caja
                from vef.tapertura_cierre_caja aper
                where aper.fecha_apertura_cierre = v_fecha_emision::date
                and aper.id_usuario_cajero = v_id_cajero_emision
                and aper.id_punto_venta = v_id_punto_venta_emision;

                if (v_estado_apertura_cierre_caja = 'cerrado' and ((v_total_efectivo_local_original - v_total_efectivo_local_modificado) != 0 or (v_total_efectivo_dolar_original - v_total_efectivo_dolar_modificado) != 0) ) then

                select pv.nombre
                	   into
                       v_nombre_punto_venta
                from vef.tpunto_venta pv
                where pv.id_punto_venta = v_id_punto_venta_emision;


                select fun.desc_funcionario1
                	    into
                        v_nombre_cajero
                from segu.vusuario usu
                inner join orga.vfuncionario fun on fun.id_persona = usu.id_persona
                where usu.id_usuario = v_id_cajero_emision;

                raise exception 'Favor contactarse con el/la Cajero(a) %, del punto de venta %. para que vuelva aperturar su caja en fecha % ya que se esta afectando en su efectivo',v_nombre_cajero,v_nombre_punto_venta,to_char(v_fecha_emision,'DD/MM/YYYY');

                end if;
                /***********************************/

                /*Recuperamos todos los medios de pago del boleto a modificar*/
                for v_record_recuperado in (
                									select fp.*
                                                    from obingresos.tboleto_amadeus ama
                                                    inner join obingresos.tboleto_amadeus_forma_pago fp on fp.id_boleto_amadeus = ama.id_boleto_amadeus
                                                    where ama.id_boleto_amadeus = v_id_boleto_amadeus_el) LOOP

                insert into obingresos.tlog_modificaciones_medios_pago_completo(
                                                                        importe,--1
                                                                        id_medio_pago,--2
                                                                        id_moneda,--3
                                                                        numero_tarjeta,--4
                                                                        codigo_tarjeta,--5
                                                                        tarjeta,--6
                                                                        id_auxiliar,--7
                                                                        mco,--8
                                                                        id_venta,--9
                                                                        nro_boleto,--10
                                                                        fecha_emision,--11
                                                                        observaciones,--12
                                                                        id_usuario_reg,--13
                                                                        fecha_reg,--14
                                                                        id_usuario_ai,--15
                                                                        usuario_ai,--16
                                                                        id_usuario_mod,--17
                                                                        fecha_mod--18
                                                                    ) values(
                                                                        v_record_recuperado.importe,--1
                                                                        v_record_recuperado.id_medio_pago,--2
                                                                        v_record_recuperado.id_moneda,--3
                                                                        v_record_recuperado.numero_tarjeta,--4
                                                                        v_record_recuperado.codigo_tarjeta,--5
                                                                        v_record_recuperado.tarjeta,--6
                                                                        v_record_recuperado.id_auxiliar,--7
                                                                        v_record_recuperado.mco,--8
                                                                        v_record_recuperado.id_venta,--9
                                                                        trim(v_parametros.boleto),--10
                                                                        v_parametros.fecha_boleto::date,--11
                                                                        v_parametros.observaciones,--12
                                                                        p_id_usuario,--13
                                                                        now(),--14
                                                                        v_parametros._id_usuario_ai,--15
                                                                        v_parametros._nombre_usuario_ai,--16
                                                                        null,--17
                                                                        null--18
                                                                    );




                END LOOP;
                /*************************************************************/


                /*Eliminamos los medios de pago del boletos relacionado*/
                delete from obingresos.tboleto_amadeus_forma_pago
          		where id_boleto_amadeus = v_id_boleto_amadeus_el;
                /*******************************************************/



            	for i in 1..(v_parametros.cantidad_fp) loop

                	v_data = 'medio_pago_'||i;

                    v_datos_recuperar = v_parametros.json_data :: JSON ->> v_data;

                    FOR  v_record_json_data_detalle IN (SELECT * FROM json_array_elements(v_datos_recuperar :: JSON))

                    loop

                    /*Recuperamos el codigo de la forma de pago y en el cod de la tarjeta para el control de tarjetas*/
                    SELECT mp.name,
                           mp.mop_code,
                           fp.fop_code
                        into
                            v_name_mp,
                            v_codigo_tarjeta_control,
                            v_codigo_fp_control
                    from obingresos.tmedio_pago_pw mp
                    inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
                    where mp.id_medio_pago_pw = (v_record_json_data_detalle->>'id_medio_pago')::integer;


                    /** control de saldo para medio de pago recibo anticipo si saldos son menores o iguales a 0 no permite el pago***/
					if (v_codigo_fp_control = 'RANT') then
                      select codigo into v_mon_recibo from param.tmoneda where id_moneda = (v_record_json_data_detalle->>'id_moneda')::integer;

                      if (v_record_json_data_detalle->>'saldo_recibo' = '') then
                      	 raise exception 'El número de recibo no puede ser vacio favor verifique';
                      end if;

                      if (((v_record_json_data_detalle->>'monto_fp')::numeric > (v_record_json_data_detalle->>'saldo_recibo')::numeric) or ((v_record_json_data_detalle->>'saldo_recibo')::numeric <= 0 and (v_record_json_data_detalle->>'saldo_recibo')::numeric is not null)) then
                         raise 'El saldo del recibo es: % % Falta un monto de % % para la forma de pago recibo anticipo.',v_mon_recibo,(v_record_json_data_detalle->>'saldo_recibo')::numeric, v_mon_recibo, (v_record_json_data_detalle->>'monto_fp')::numeric-(v_record_json_data_detalle->>'saldo_recibo')::numeric;
                      end if;
                    end if;
                    /******************************************************************************************************************/



                    /*Control para el numero y codigo de la tarjeta*/
                      if (v_codigo_fp_control = 'CU') then
                        if ((v_record_json_data_detalle->>'id_auxiliar')::varchar = '') then
                            Raise exception 'La Cuenta Corriente no puede ser vacia, Favor verifique';
                        end if;
                      end if;
                    /***********************************************/

                    v_codigo_tarjeta_control = (case when v_codigo_tarjeta_control is not null then
                                              v_codigo_tarjeta_control
                                          else
                                              NULL
                                          end);

                      if (v_codigo_tarjeta_control is not null and v_codigo_fp_control = 'CC') then
                      	/*Control para el numero y codigo de la tarjeta*/
                        if ((v_record_json_data_detalle->>'numero_tarjeta')::varchar = '' or (v_record_json_data_detalle->>'numero_tarjeta')::varchar is null) then
                        	Raise exception 'El Nro. de Tarjeta no puede ser vacio favor verifique';
                        end if;

                         if ((v_record_json_data_detalle->>'codigo_tarjeta')::varchar = '' or (v_record_json_data_detalle->>'codigo_tarjeta')::varchar is null) then
                        	Raise exception 'El Cod. de Tarjeta no puede ser vacio favor verifique';
                        end if;

                        if( select char_length((v_record_json_data_detalle->>'codigo_tarjeta')::varchar) <> 6)then
                            raise exception 'El codigo de tarjeta debe tener 6 dígitos verifique.';
                        end if;
                      	/***********************************************/


                          if (substring((v_record_json_data_detalle->>'numero_tarjeta')::varchar from 1 for 1) != 'X') then
                             v_res = pxp.f_valida_numero_tarjeta_credito((v_record_json_data_detalle->>'numero_tarjeta')::varchar,v_codigo_tarjeta_control);
                          end if;
                      end if;
                    /*******************************************************************************************************/

                    /*Control del Nro de MCO*/

                      /*Control para el numero y codigo de la tarjeta*/
                      if (v_codigo_fp_control = 'MCO') then
                        if ((v_record_json_data_detalle->>'mco')::varchar = '' or (v_record_json_data_detalle->>'mco')::varchar is null) then
                            Raise exception 'El Nro. de MCO no puede ser vacio favor verifique';
                        end if;
                      end if;
                      /***********************************************/

                      if ((v_record_json_data_detalle->>'mco')::varchar is not null and left ((v_record_json_data_detalle->>'mco')::varchar,3)<> '930' and (v_record_json_data_detalle->>'mco')::varchar <> '' )then
                          raise exception 'Segunda forma de pago el numero del MCO tiene que empezar con 930';
                      end if;

                      if ((v_record_json_data_detalle->>'mco')::varchar is not null and char_length((v_record_json_data_detalle->>'mco')::varchar) <> 15 and (v_record_json_data_detalle->>'mco')::varchar <> '') then
                          raise exception 'Segunda forma de pago el numero del MCO debe tener 15 digitos obligatorios, 930000000012345';
                      end if;
                    /************************/

                    IF ((v_record_json_data_detalle->>'monto_fp') = '') THEN
                            raise 'El monto de la forma de pago no puede ser vacio ni cero';
                    END IF;

                      /*Controlamos que los montos de las formas de pago no sean 0*/
                      IF ((v_record_json_data_detalle->>'monto_fp')::numeric <= 0) THEN
                            raise 'No se permite Medios de pago con Monto menor o igual a cero';
                      END IF;
                      /*************************************************************/


                      if ((v_record_json_data_detalle->>'id_auxiliar')::varchar != '') then
                          v_id_auxiliar = (v_record_json_data_detalle->>'id_auxiliar')::integer;
                      else
                      	  v_id_auxiliar = null;
                      end if;

                      if ((v_record_json_data_detalle->>'id_venta')::varchar != '') then
                          v_id_venta = (v_record_json_data_detalle->>'id_venta')::integer;
                      else
                      	  v_id_venta = null;
                      end if;



                      /*Insertamos el nuevo medio de pago*/
                      INSERT INTO
                        obingresos.tboleto_amadeus_forma_pago
                      (
                        id_usuario_reg,
                        importe,
                        id_medio_pago,
                        id_boleto_amadeus,
                        id_moneda,
                        --ctacte,
                        numero_tarjeta,
                        codigo_tarjeta,
                        tarjeta,
                        id_usuario_fp_corregido,
                        id_auxiliar,
                        registro_mod,
                        mco--,
                        --modificado
                        ,id_venta
                      )
                      VALUES (
                        p_id_usuario,
                        (v_record_json_data_detalle->>'monto_fp')::numeric,
                        (v_record_json_data_detalle->>'id_medio_pago')::integer,
                        v_id_boleto_amadeus_el,
                        (v_record_json_data_detalle->>'id_moneda')::integer,
                        --v_parametros.ctacte,
                        (v_record_json_data_detalle->>'numero_tarjeta')::varchar,
                        replace(upper((v_record_json_data_detalle->>'codigo_tarjeta')::varchar),' ',''),
                        v_codigo_tarjeta_control,
                        p_id_usuario,
                        v_id_auxiliar,
                        null,
                        (v_record_json_data_detalle->>'mco')::varchar--,
                        --'si'
                        ,v_id_venta
                      );
                     /*************************************************/

                    end loop;


                end loop;

                select count(*) into v_cantidad_fp
                from obingresos.tboleto_amadeus_forma_pago
                where id_boleto_amadeus =   v_id_boleto_amadeus_el;

                v_acumulado_fp = 0;

                /*Aqui control de montos para el total de la venta*/
                for v_registros in (  select bol.id_medio_pago,
                                             bol.id_moneda,
                                             bol.importe
                                      from obingresos.tboleto_amadeus_forma_pago bol
                                      where bol.id_boleto_amadeus = v_id_boleto_amadeus_el) loop


                  select mon.id_moneda
                  INTO
                  v_id_moneda_base
                  from param.tmoneda mon
                  where mon.tipo_moneda = 'base';


                  /*Aqui condicionales para el tipo de cambio y tener la moneda en dolar como en bs*/
                  if (v_registros.id_moneda = 2 and v_id_moneda_venta = 2) then

                      v_monto_fp =  param.f_convertir_moneda(v_registros.id_moneda,v_id_moneda_base,v_registros.importe,v_fecha_emision::date,'CUS',2, NULL,'si');
                      v_monto_total_base = param.f_convertir_moneda(v_id_moneda_venta,v_id_moneda_base,v_monto_total_boleto,v_fecha_emision::date,'CUS',2, NULL,'si');

                  elsif (v_registros.id_moneda != 2 and v_id_moneda_venta = 2) then

                      v_monto_fp = v_registros.importe;
                      v_monto_total_base = param.f_convertir_moneda(v_id_moneda_venta,v_id_moneda_base,v_monto_total_boleto,v_fecha_emision::date,'CUS',2, NULL,'si');

                  elsif (v_registros.id_moneda = 2 and v_id_moneda_venta != 2) then

                      v_monto_fp = param.f_convertir_moneda(v_registros.id_moneda,v_id_moneda_base,v_registros.importe,v_fecha_emision::date,'CUS',2, NULL,'si');
                      v_monto_total_base = v_monto_total_boleto;

                  elsif (v_registros.id_moneda != 2 and v_id_moneda_venta != 2) then

                      v_monto_fp = v_registros.importe;
                      v_monto_total_base = v_monto_total_boleto;

                  end if;


                  if (v_monto_fp >= v_monto_total_base and v_cantidad_fp > 1) then
                    raise exception 'Se ha definido mas de una forma de pago, pero existe una que supera el valor de la venta(solo se requiere una forma de pago)';
                  end if;


                  if (v_monto_fp > v_monto_total_base and v_cantidad_fp = 1) then
                    raise exception 'El monto ingresado % en la forma de pago supera el total de la venta %, favor verifique',v_monto_fp,v_monto_total_base;
                  end if;


                  v_acumulado_fp = v_acumulado_fp + v_monto_fp;


                end loop;
               /**************************************************/


               /*Aqui Controlamos que el total cobrado sea igual o mayor a la venta en dolar*/
               select sum(round(fp.importe,2)) into v_suma_fp_dolar
               from obingresos.tboleto_amadeus_forma_pago fp
               where fp.id_boleto_amadeus = v_id_boleto_amadeus_el
               and fp.id_moneda = 2;
               /********************************************************************/

               v_suma_fp_dolar = param.f_convertir_moneda(2,v_id_moneda_base,(COALESCE(v_suma_fp_dolar,0)),v_fecha_emision::date,'CUS',2, NULL,'si');

               select sum(round(fp.importe,2)) into v_suma_fp_bolivianos
               from obingresos.tboleto_amadeus_forma_pago fp
               where fp.id_boleto_amadeus = v_id_boleto_amadeus_el
               and fp.id_moneda = 1;

               v_suma_total = COALESCE (v_suma_fp_bolivianos,0) + COALESCE (v_suma_fp_dolar,0);

               --raise exception 'Aqui el total %',v_suma_total;

              if (v_suma_total < v_monto_total_base) then

              	v_conversion_dolar = param.f_convertir_moneda(v_id_moneda_base,2,(COALESCE((v_monto_total_base - v_suma_total),0)),v_fecha_emision::date,'CUS',2, NULL,'si');


                raise exception 'El importe recibido es menor al valor de la venta, falta % BOB o % USD', (v_monto_total_base - v_suma_total), v_conversion_dolar;
              end if;


              --Definicion de la respuesta
              v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Modificacion Exitosa');
              v_resp = pxp.f_agrega_clave(v_resp,'establecimiento','Modificacion de formas de pago Correctamente');

              --Devuelve la respuesta
              return v_resp;

            end;

    /*********************************
        #TRANSACCION:  'KIU_CONTROL_MP_IME'
        #DESCRIPCION:	Control para los Medios de Pago de un Boleto para Stage
        #AUTOR:		Ismael Valdivia
        #FECHA:		19-08-2021 16:00:00
        ***********************************/

        elsif(p_transaccion='KIU_CONTROL_MP_IME')then

            begin

            	/*Creamos la tabla temporal para que insertemos ahi para hacer el calculo*/
                create temp table medio_pago_temporal_stage (
                                                                id_moneda integer,
                                                                importe numeric
                                                              )on commit drop;
                /*************************************************************************/




            	for i in 1..(v_parametros.cantidad_fp) loop

                	v_data = 'medio_pago_'||i;

                    v_datos_recuperar = v_parametros.json_data :: JSON ->> v_data;

                    FOR  v_record_json_data_detalle IN (SELECT * FROM json_array_elements(v_datos_recuperar :: JSON))

                    loop

                    /*Recuperamos el codigo de la forma de pago y en el cod de la tarjeta para el control de tarjetas*/
                    SELECT mp.name,
                           mp.mop_code,
                           fp.fop_code
                        into
                            v_name_mp,
                            v_codigo_tarjeta_control,
                            v_codigo_fp_control
                    from obingresos.tmedio_pago_pw mp
                    inner join obingresos.tforma_pago_pw fp on fp.id_forma_pago_pw = mp.forma_pago_id
                    where mp.id_medio_pago_pw = (v_record_json_data_detalle->>'id_medio_pago')::integer;


                    /** control de saldo para medio de pago recibo anticipo si saldos son menores o iguales a 0 no permite el pago***/
					if (v_codigo_fp_control = 'RANT') then
                      select codigo into v_mon_recibo from param.tmoneda where id_moneda = (v_record_json_data_detalle->>'id_moneda')::integer;

                      if (v_record_json_data_detalle->>'saldo_recibo' = '') then
                      	 raise exception 'El número de recibo no puede ser vacio favor verifique';
                      end if;

                      if (((v_record_json_data_detalle->>'monto_fp')::numeric > (v_record_json_data_detalle->>'saldo_recibo')::numeric) or ((v_record_json_data_detalle->>'saldo_recibo')::numeric <= 0 and (v_record_json_data_detalle->>'saldo_recibo')::numeric is not null)) then
                         raise 'El saldo del recibo es: % % Falta un monto de % % para la forma de pago recibo anticipo.',v_mon_recibo,(v_record_json_data_detalle->>'saldo_recibo')::numeric, v_mon_recibo, (v_record_json_data_detalle->>'monto_fp')::numeric-(v_record_json_data_detalle->>'saldo_recibo')::numeric;
                      end if;
                    end if;
                    /******************************************************************************************************************/



                    /*Control para el numero y codigo de la tarjeta*/
                      if (v_codigo_fp_control = 'CU') then
                        if ((v_record_json_data_detalle->>'id_auxiliar')::varchar = '') then
                            Raise exception 'La Cuenta Corriente no puede ser vacia, Favor verifique';
                        end if;
                      end if;
                    /***********************************************/

                    v_codigo_tarjeta_control = (case when v_codigo_tarjeta_control is not null then
                                              v_codigo_tarjeta_control
                                          else
                                              NULL
                                          end);

                      if (v_codigo_tarjeta_control is not null and v_codigo_fp_control = 'CC') then
                      	/*Control para el numero y codigo de la tarjeta*/
                        if ((v_record_json_data_detalle->>'numero_tarjeta')::varchar = '' or (v_record_json_data_detalle->>'numero_tarjeta')::varchar is null) then
                        	Raise exception 'El Nro. de Tarjeta no puede ser vacio favor verifique';
                        end if;

                         if ((v_record_json_data_detalle->>'codigo_tarjeta')::varchar = '' or (v_record_json_data_detalle->>'codigo_tarjeta')::varchar is null) then
                        	Raise exception 'El Cod. de Tarjeta no puede ser vacio favor verifique';
                        end if;

                        if( select char_length((v_record_json_data_detalle->>'codigo_tarjeta')::varchar) <> 6)then
                            raise exception 'El codigo de tarjeta debe tener 6 dígitos verifique.';
                        end if;
                      	/***********************************************/


                          if (substring((v_record_json_data_detalle->>'numero_tarjeta')::varchar from 1 for 1) != 'X') then
                             v_res = pxp.f_valida_numero_tarjeta_credito((v_record_json_data_detalle->>'numero_tarjeta')::varchar,v_codigo_tarjeta_control);
                          end if;
                      end if;
                    /*******************************************************************************************************/

                    /*Control del Nro de MCO*/

                      /*Control para el numero y codigo de la tarjeta*/
                      if (v_codigo_fp_control = 'MCO') then
                        if ((v_record_json_data_detalle->>'mco')::varchar = '' or (v_record_json_data_detalle->>'mco')::varchar is null) then
                            Raise exception 'El Nro. de MCO no puede ser vacio favor verifique';
                        end if;
                      end if;
                      /***********************************************/

                      if ((v_record_json_data_detalle->>'mco')::varchar is not null and left ((v_record_json_data_detalle->>'mco')::varchar,3)<> '930' and (v_record_json_data_detalle->>'mco')::varchar <> '' )then
                          raise exception 'Segunda forma de pago el numero del MCO tiene que empezar con 930';
                      end if;

                      if ((v_record_json_data_detalle->>'mco')::varchar is not null and char_length((v_record_json_data_detalle->>'mco')::varchar) <> 15 and (v_record_json_data_detalle->>'mco')::varchar <> '') then
                          raise exception 'Segunda forma de pago el numero del MCO debe tener 15 digitos obligatorios, 930000000012345';
                      end if;
                    /************************/

                     IF ((v_record_json_data_detalle->>'monto_fp') = '') THEN
                            raise 'El monto de la forma de pago no puede ser vacio ni cero';
                      END IF;

                      /*Controlamos que los montos de las formas de pago no sean 0*/
                      IF ((v_record_json_data_detalle->>'monto_fp')::numeric <= 0) THEN
                            raise 'No se permite Medios de pago con Monto menor o igual a cero';
                      END IF;
                      /*************************************************************/

                      /*Insertamos el nuevo medio de pago*/
                      INSERT INTO
                        medio_pago_temporal_stage
                      (
                        id_moneda,
                        importe
                      )
                      VALUES (
                        (v_record_json_data_detalle->>'id_moneda')::integer,
                        (v_record_json_data_detalle->>'monto_fp')::numeric
                      );
                     /*************************************************/

                    end loop;


                end loop;

                select count(*) into v_cantidad_fp
                from medio_pago_temporal_stage;

                v_acumulado_fp = 0;

                /*Aqui control de montos para el total de la venta*/
                for v_registros in (  select id_moneda,
                                             importe
                                      from medio_pago_temporal_stage) loop


                  select mon.id_moneda
                  INTO
                  v_id_moneda_base
                  from param.tmoneda mon
                  where mon.tipo_moneda = 'base';

                  select mon.id_moneda into v_id_moneda_venta
                  from param.tmoneda mon
                  where mon.codigo_internacional = v_parametros.moneda_venta;

                  v_fecha_emision = v_parametros.fecha_boleto::date;

                  v_monto_total_boleto = v_parametros.total_venta - v_parametros.comision_venta;


                  /*Aqui condicionales para el tipo de cambio y tener la moneda en dolar como en bs*/
                  if (v_registros.id_moneda = 2 and v_id_moneda_venta = 2) then

                      v_monto_fp =  param.f_convertir_moneda(v_registros.id_moneda,v_id_moneda_base,v_registros.importe,v_fecha_emision::date,'CUS',2, NULL,'si');
                      v_monto_total_base = param.f_convertir_moneda(v_id_moneda_venta,v_id_moneda_base,v_monto_total_boleto,v_fecha_emision::date,'CUS',2, NULL,'si');

                  elsif (v_registros.id_moneda != 2 and v_id_moneda_venta = 2) then

                      v_monto_fp = v_registros.importe;
                      v_monto_total_base = param.f_convertir_moneda(v_id_moneda_venta,v_id_moneda_base,v_monto_total_boleto,v_fecha_emision::date,'CUS',2, NULL,'si');

                  elsif (v_registros.id_moneda = 2 and v_id_moneda_venta != 2) then

                      v_monto_fp = param.f_convertir_moneda(v_registros.id_moneda,v_id_moneda_base,v_registros.importe,v_fecha_emision::date,'CUS',2, NULL,'si');
                      v_monto_total_base = v_monto_total_boleto;

                  elsif (v_registros.id_moneda != 2 and v_id_moneda_venta != 2) then

                      v_monto_fp = v_registros.importe;
                      v_monto_total_base = v_monto_total_boleto;

                  end if;


                  if (v_monto_fp >= v_monto_total_base and v_cantidad_fp > 1) then
                    raise exception 'Se ha definido mas de una forma de pago, pero existe una que supera el valor de la venta(solo se requiere una forma de pago)';
                  end if;


                  if (v_monto_fp > v_monto_total_base and v_cantidad_fp = 1) then
                    raise exception 'El monto ingresado % en la forma de pago supera el total de la venta %, favor verifique',v_monto_fp,v_monto_total_base;
                  end if;


                  v_acumulado_fp = v_acumulado_fp + v_monto_fp;


                end loop;
               /**************************************************/


               /*Aqui Controlamos que el total cobrado sea igual o mayor a la venta en dolar*/
               select sum(round(fp.importe,2)) into v_suma_fp_dolar
               from medio_pago_temporal_stage fp
               where fp.id_moneda = 2;
               /********************************************************************/

               v_suma_fp_dolar = param.f_convertir_moneda(2,v_id_moneda_base,(COALESCE(v_suma_fp_dolar,0)),v_fecha_emision::date,'CUS',2, NULL,'si');

               select sum(round(fp.importe,2)) into v_suma_fp_bolivianos
               from medio_pago_temporal_stage fp
               where fp.id_moneda = 1;

               v_suma_total = COALESCE (v_suma_fp_bolivianos,0) + COALESCE (v_suma_fp_dolar,0);


              if (v_suma_total < v_monto_total_base) then

              	v_conversion_dolar = param.f_convertir_moneda(v_id_moneda_base,2,(COALESCE((v_monto_total_base - v_suma_total),0)),v_fecha_emision::date,'CUS',2, NULL,'si');


                raise exception 'El importe recibido es menor al valor de la venta, falta % BOB o % USD', (v_monto_total_base - v_suma_total), v_conversion_dolar;
              end if;


              --Definicion de la respuesta
              v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Modificacion Exitosa');
              v_resp = pxp.f_agrega_clave(v_resp,'establecimiento','Modificacion de formas de pago Correctamente');

              --Devuelve la respuesta
              return v_resp;

            end;

    /*********************************
        #TRANSACCION:  'KIU_MP_DEFAULT_IME'
        #DESCRIPCION:	Recuperacion del Medio de pago por defecto
        #AUTOR:		Ismael Valdivia
        #FECHA:		24-08-2021 11:00:00
        ***********************************/

        elsif(p_transaccion='KIU_MP_DEFAULT_IME')then

            begin

                if (pxp.f_existe_parametro(p_tabla,'description_mp')) then
                  v_description_mp = trim(v_parametros.description_mp);
                else
                  v_description_mp = '';
                end if;

                if (pxp.f_existe_parametro(p_tabla,'codigo_medio_pago')) then
                  v_codigo_medio_pago_mp = trim(v_parametros.codigo_medio_pago);
                else
                  v_codigo_medio_pago_mp = '';
                end if;


            	if (v_description_mp = 'CASH') then
                	v_medio_pago = 'CASH';
                else
                	v_medio_pago = v_codigo_medio_pago_mp;
                end if;


                if (v_medio_pago != '') then
            	  SELECT TO_JSON(ROW_TO_JSON(jsonData) :: TEXT) #>> '{}' as json
					into v_json_medio_pago_id
                    from (
                    SELECT
                         (
                            SELECT ARRAY_TO_JSON(ARRAY_AGG(ROW_TO_JSON(medio_pago)))
                             FROM
                                 (
                                      select mp.id_medio_pago_pw as id_forma_pago,
                                      mp.name as nombre
                                      from obingresos.tmedio_pago_pw mp
                                      where 'BOLETOS'=any(mp.sw_autorizacion) and 'BOL'=any(mp.regionales)
                                      and mp.mop_code = v_medio_pago
                                 ) medio_pago
                             ) as data_medio_pago
                    ) jsonData;
                  end if;
                   --  raise exception 'Aqui la respuesta %',v_establecimiento;
                 --Definicion de la respuesta
                  v_resp = pxp.f_agrega_clave(v_resp,'mensaje',v_json_medio_pago_id);
                  v_resp = pxp.f_agrega_clave(v_resp,'medio_pago',v_json_medio_pago_id);

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
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION kiu.ft_boa_kiu_json (p_administrador integer, p_id_usuario integer, p_tabla varchar, p_transaccion varchar)
  OWNER TO postgres;
