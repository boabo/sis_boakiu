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
    v_id_moneda	varchar[];
    v_id_forma_pago varchar[];
    v_num_tarjeta varchar[];
    v_cod_tarjeta varchar[];
    v_mco varchar[];
    v_id_auxiliar varchar[];
    v_id_auxiliar_anticipo varchar[];
    v_id_venta varchar[];
    v_monto_fp varchar[];


    v_name_mp	varchar;
    v_codigo_moneda	varchar;

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
                         ) AS nota_debito_credito

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


            select ama.id_boleto_amadeus
            into
                v_id_boleto_amadeus
            from obingresos.tboleto_amadeus ama
            where trim(ama.nro_boleto) = trim(v_parametros.boleto_a_modificar);



            select count (fp.id_boleto_amadeus_forma_pago)
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




            end if;



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

            	v_id_moneda = string_to_array(Replace(Replace(Replace(v_parametros.id_moneda :: JSON ->> 'id_moneda', '"',''),'[',''),']',''),',');
                v_id_forma_pago = string_to_array(Replace(Replace(Replace(v_parametros.id_forma_pago :: JSON ->> 'id_forma_pago', '"',''),'[',''),']',''),',');
                v_num_tarjeta = string_to_array(Replace(Replace(Replace(v_parametros.num_tarjeta :: JSON ->> 'num_tarjeta', '"',''),'[',''),']',''),',');
                v_cod_tarjeta = string_to_array(Replace(Replace(Replace(v_parametros.cod_tarjeta :: JSON ->> 'cod_tarjeta', '"',''),'[',''),']',''),',');
                v_mco = string_to_array(Replace(Replace(Replace(v_parametros.mco :: JSON ->> 'mco', '"',''),'[',''),']',''),',');
                v_id_auxiliar = string_to_array(Replace(Replace(Replace(v_parametros.id_auxiliar :: JSON ->> 'id_auxiliar', '"',''),'[',''),']',''),',');
                v_id_auxiliar_anticipo = string_to_array(Replace(Replace(Replace(v_parametros.id_auxiliar_anticipo :: JSON ->> 'id_auxiliar_anticipo', '"',''),'[',''),']',''),',');
                v_id_venta = string_to_array(Replace(Replace(Replace(v_parametros.id_venta :: JSON ->> 'id_venta', '"',''),'[',''),']',''),',');
                v_monto_fp = string_to_array(Replace(Replace(Replace(v_parametros.monto_fp :: JSON ->> 'monto_fp', '"',''),'[',''),']',''),',');


            	for i in 1..(v_parametros.cantidad_fp) loop

                	select mon.codigo_internacional into v_codigo_moneda
                    from param.tmoneda mon
                    where mon.id_moneda = v_id_moneda[i]::integer;

                    SELECT mp.name into v_name_mp
                    from obingresos.tmedio_pago_pw mp
                    where mp.id_medio_pago_pw = v_id_forma_pago[i]::integer;

                    raise notice 'Aqui llega la informacion %, %',v_codigo_moneda,v_name_mp;

                end loop;

               -- raise exception 'Aqui llega la respuesta %',v_parametros.cantidad_fp;

                 --Definicion de la respuesta
                  --v_resp = pxp.f_agrega_clave(v_resp,'mensaje',v_establecimiento);
                  --v_resp = pxp.f_agrega_clave(v_resp,'establecimiento',v_establecimiento);

                  --Devuelve la respuesta
                  --return v_resp;

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
