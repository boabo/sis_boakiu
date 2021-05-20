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

        //Ejecuta la instruccion
        $this->armarConsulta();
        $this->ejecutarConsulta();

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


}
?>