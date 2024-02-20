<?php
/**
 *@package pXP
 *@file gen-MODLiquidacion.php
 *@author  (admin)
 *@date 17-04-2020 01:54:37
 *@description Clase que envia los parametros requeridos a la Base de datos para la ejecucion de las funciones, y que recibe la respuesta del resultado de la ejecucion de las mismas
HISTORIAL DE MODIFICACIONES:
#ISSUE				FECHA				AUTOR				DESCRIPCION
#0				17-04-2020 01:54:37								CREACION

 */

class MODBoleto extends MODbase{

    function __construct(CTParametro $pParam){
        parent::__construct($pParam);
    }

    function verFacturaErpBoleto(){
        //Definicion de variables para ejecucion del procedimiento
        $this->procedimiento='kiu.ft_boa_kiu_json';
        $this->transaccion='KIU_GETFAC_JSON_SEL';
        $this->tipo_procedimiento='IME';

        //Define los parametros para la funcion
        $this->setParametro('nro_ticket','nro_ticket','varchar');
        $this->setParametro('fecha_boleto','fecha_boleto','varchar');
        $this->setParametro('formato','formato','varchar');
        $this->setParametro('codigo_agente','codigo_agente','varchar');

        //Ejecuta la instruccion
        $this->armarConsulta();
        $this->ejecutarConsulta();
        //var_dump($this->respuesta);exit;
        //Devuelve la respuesta
        return $this->respuesta;
    }
    function guardarLogAnularBoleto(){
        //Definicion de variables para ejecucion del procedimiento
        $this->procedimiento='kiu.ft_boa_kiu_json';
        $this->transaccion='KIU_LOGANU_JSON_IME';
        $this->tipo_procedimiento='IME';

        //Define los parametros para la funcion
        $this->setParametro('boleto','boleto','varchar');
        $this->setParametro('motivo','motivo','varchar');
        $this->setParametro('mensaje_erp','mensaje_erp','varchar');
        $this->setParametro('mensaje_stage','mensaje_stage','varchar');
        $this->setParametro('anulado_erp','anulado_erp','varchar');
        $this->setParametro('anulado_stage','anulado_stage','varchar');

        //Ejecuta la instruccion
        $this->armarConsulta();
        $this->ejecutarConsulta();

        //Devuelve la respuesta
        return $this->respuesta;
    }

    function modificarTarjetasErp(){
  		//Definicion de variables para ejecucion del procedimiento
  		$this->procedimiento='kiu.ft_boa_kiu_json';
  		$this->transaccion='KIU_MOD_TARJE_ERP';
  		$this->tipo_procedimiento='IME';

      $this->setParametro('boleto_a_modificar','boleto_a_modificar','varchar');
      $this->setParametro('fecha_emision','fecha_emision','date');
      $this->setParametro('forma_pago_1','forma_pago_1','integer');
      $this->setParametro('num_tarjeta_1','num_tarjeta_1','varchar');
      $this->setParametro('cod_tarjeta_1','cod_tarjeta_1','varchar');
      $this->setParametro('monto_fp_1','monto_fp_1','numeric');
      $this->setParametro('nro_tarjeta_1_old','nro_tarjeta_1_old','varchar');
      $this->setParametro('nro_autorizacion_1_old','nro_autorizacion_1_old','varchar');

      $this->setParametro('forma_pago_2','forma_pago_2','integer');
      $this->setParametro('num_tarjeta_2','num_tarjeta_2','varchar');
      $this->setParametro('cod_tarjeta_2','cod_tarjeta_2','varchar');
      $this->setParametro('monto_fp_2','monto_fp_2','numeric');
      $this->setParametro('nro_tarjeta_2_old','nro_tarjeta_2_old','varchar');
      $this->setParametro('nro_autorizacion_2_old','nro_autorizacion_2_old','varchar');



  		//Ejecuta la instruccion
  		$this->armarConsulta();
  		$this->ejecutarConsulta();

  		//Devuelve la respuesta
  		return $this->respuesta;
  	}

    function logModificaciones(){
        //Definicion de variables para ejecucion del procedimiento
        $this->procedimiento='kiu.ft_boa_kiu_json';
        $this->transaccion='KIU_LOGMODI_JSON_IME';
        $this->tipo_procedimiento='IME';

        //Define los parametros para la funcion
        $this->setParametro('nro_boleto','nro_boleto','varchar');
        $this->setParametro('nro_tarjeta_1_old','nro_tarjeta_1_old','varchar');
        $this->setParametro('nro_autorizacion_1_old','nro_autorizacion_1_old','varchar');
        $this->setParametro('nro_tarjeta_2_old','nro_tarjeta_2_old','varchar');
        $this->setParametro('nro_autorizacion_2_old','nro_autorizacion_2_old','varchar');

        $this->setParametro('num_tarjeta_1','num_tarjeta_1','varchar');
        $this->setParametro('cod_tarjeta_1','cod_tarjeta_1','varchar');

        $this->setParametro('num_tarjeta_2','num_tarjeta_2','varchar');
        $this->setParametro('cod_tarjeta_2','cod_tarjeta_2','varchar');

        $this->setParametro('observaciones','observaciones','varchar');
        $this->setParametro('forma_pago_1','forma_pago_1','integer');
        $this->setParametro('forma_pago_2','forma_pago_2','integer');
        //Ejecuta la instruccion
        $this->armarConsulta();
        $this->ejecutarConsulta();

        //Devuelve la respuesta
        return $this->respuesta;
    }


    function recuperarNombreEstablecimiento() {

      $this->procedimiento='kiu.ft_boa_kiu_json';
      $this->transaccion='KIU_NAME_COMER_IME';
      $this->tipo_procedimiento='IME';

      //var_dump("aqui el nro",$this->objParam->getParametro('nro_comercio'));
      //Define los parametros para la funcion
      $this->setParametro('nro_comercio','nro_comercio','varchar');

      //Ejecuta la instruccion
      $this->armarConsulta();
      $this->ejecutarConsulta();

      //Devuelve la respuesta
      return $this->respuesta;


    }


}
?>
