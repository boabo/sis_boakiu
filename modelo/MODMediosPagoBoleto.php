<?php
/**
 *@package pXP
 *@file gen-MODMediosPagoBoleto.php
 *@author  (Ismael Valdivia)
 *@date 20-07-2021 11:54:37
 *@description Clase que envia los parametros requeridos a la Base de datos para la ejecucion de las funciones, y que recibe la respuesta del resultado de la ejecucion de las mismas
 */

class MODMediosPagoBoleto extends MODbase{

    function __construct(CTParametro $pParam){
        parent::__construct($pParam);
    }
    function ModificarMedioPago() {

      $this->procedimiento='kiu.ft_boa_kiu_json';
      $this->transaccion='KIU_MOD_MP_IME';
      $this->tipo_procedimiento='IME';

      //var_dump("aqui el nro",$this->objParam->getParametro('id_moneda'));
      //Define los parametros para la funcion
      // $this->setParametro('id_moneda','id_moneda','text');
      // $this->setParametro('id_forma_pago','id_forma_pago','text');
      // $this->setParametro('num_tarjeta','num_tarjeta','text');
      // $this->setParametro('cod_tarjeta','cod_tarjeta','text');
      // $this->setParametro('mco','mco','text');
      // $this->setParametro('id_auxiliar','id_auxiliar','text');
      // $this->setParametro('id_auxiliar_anticipo','id_auxiliar_anticipo','text');
      // $this->setParametro('id_venta','id_venta','text');
      $this->setParametro('json_data','json_data','text');
      $this->setParametro('cantidad_fp','cantidad_fp','integer');
      $this->setParametro('boleto','boleto','varchar');
      $this->setParametro('fecha_boleto','fecha_boleto','date');
      $this->setParametro('observaciones','observaciones','varchar');
      $this->setParametro('comision_venta','comision_venta','numeric');

      //Ejecuta la instruccion
      $this->armarConsulta();
      $this->ejecutarConsulta();
    //  var_dump("aqui llega el dato",$this->respuesta);exit;
      //Devuelve la respuesta
      return $this->respuesta;

    }

    function ControlDatosMediosPAgo() {

      $this->procedimiento='kiu.ft_boa_kiu_json';
      $this->transaccion='KIU_CONTROL_MP_IME';
      $this->tipo_procedimiento='IME';

      //var_dump("aqui el nro",$this->objParam->getParametro('id_moneda'));
      //Define los parametros para la funcion
      // $this->setParametro('id_moneda','id_moneda','text');
      // $this->setParametro('id_forma_pago','id_forma_pago','text');
      // $this->setParametro('num_tarjeta','num_tarjeta','text');
      // $this->setParametro('cod_tarjeta','cod_tarjeta','text');
      // $this->setParametro('mco','mco','text');
      // $this->setParametro('id_auxiliar','id_auxiliar','text');
      // $this->setParametro('id_auxiliar_anticipo','id_auxiliar_anticipo','text');
      // $this->setParametro('id_venta','id_venta','text');
      $this->setParametro('json_data','json_data','text');
      $this->setParametro('cantidad_fp','cantidad_fp','integer');
      $this->setParametro('boleto','boleto','varchar');
      $this->setParametro('fecha_boleto','fecha_boleto','date');
      $this->setParametro('total_venta','total_venta','numeric');
      $this->setParametro('moneda_venta','moneda_venta','varchar');
      $this->setParametro('comision_venta','comision_venta','numeric');

      //Ejecuta la instruccion
      $this->armarConsulta();
      $this->ejecutarConsulta();
    //  var_dump("aqui llega el dato",$this->respuesta);exit;
      //Devuelve la respuesta
      return $this->respuesta;

    }

    function recuperarMedioPago() {

      $this->procedimiento='kiu.ft_boa_kiu_json';
      $this->transaccion='KIU_MP_DEFAULT_IME';
      $this->tipo_procedimiento='IME';

      //var_dump("aqui el nro",$this->objParam->getParametro('nro_comercio'));
      //Define los parametros para la funcion
      $this->setParametro('codigo_medio_pago','codigo_medio_pago','varchar');
      $this->setParametro('codigo_forma_pago','codigo_forma_pago','varchar');
      $this->setParametro('description_mp','description_mp','varchar');

      //Ejecuta la instruccion
      $this->armarConsulta();
      $this->ejecutarConsulta();

      //Devuelve la respuesta
      return $this->respuesta;


    }


}
?>
