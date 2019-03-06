//
//  CodeRecoveryPasswordVC.swift
//  mcaRecoveryPassword
//
//  Created by Pilar del Rosario Prospero Zeferino on 12/3/18.
//  Copyright © 2018 Speedy Movil. All rights reserved.
//

import UIKit
import mcaUtilsiOS
import mcaManageriOS
import Cartography

// Clase encargada de mostrar la vista para ingresar el código de recuperación de la contraseña
class CodeRecoveryPasswordVC: UIViewController, LinkeableEventDelegate {
    
    var doLoginWhenFinish :((_ doAutomaticLogin: Bool) -> Void) = {_ in }
    
    /// Variable que almacena el objeto GetTempPasswordRequest
    var gtpRequest : GetTempPasswordRequest?
    /// Variable que almacena el objeto GetTempPasswordResult
    var gtpResult : GetTempPasswordResult?
    /// Botón de siguiente
    var nextButton: RedBorderWhiteBackgroundButton!
    /// Contenedor de la interfáz para ingresar el código
    var codeContainer: CodeContainerView!
    /// Etiqueta para re-envío de codigo
    var linkeableLabel: LinkableLabel!
    /// Etiqueta de términos y condiciones
    var lblTerminos : LinkableLabel?;
    /// Variable que almacena el número de re-intentos máximos disponibles
    var tryOutNumbers : Int = 1
    /// Variable que almacena el número de intentos realizados
    var tryAttemps : Int = 1
    /// Variable que almacena el número de intentos realizados para re-envío
    var tryAttempsResend : Int = 1
    
    private let conf = mcaManagerSession.getGeneralConfig()
    private var headerView : UIHeaderForm = UIHeaderForm(frame: .zero)
    private var questionLabel : UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: RobotoFontName.RobotoRegular.rawValue, size: 14.0)
        label.textColor = institutionalColors.claroBlackColor
        label.textAlignment = .center
        return label
    }()
    
    
    func setupElements() {
        self.view.backgroundColor = institutionalColors.claroWhiteColor
        let scrollView = UIScrollView(frame: .zero)
        let viewContainer = UIView(frame: self.view.bounds)
        headerView.setupElements(imageName: "ico_seccion_pass", title: conf?.translations?.data?.passwordRecovery?.title, subTitle: conf?.translations?.data?.registro?.pinValidation)
        viewContainer.addSubview(headerView)
        codeContainer = CodeContainerView()
        codeContainer.frame = CGRect(x: 0, y: 0, width: self.view.frame.width * 0.45, height: 40)
        codeContainer.numberCode =  6
        codeContainer.setPosition()
        viewContainer.addSubview(codeContainer)
        questionLabel.text = conf?.translations?.data?.registro?.pinValidationResendText != nil ? (conf?.translations?.data?.registro?.pinValidationResendText)! : "¿No te ha llegado el código?"
        viewContainer.addSubview(questionLabel)
        let tapCheck = UITapGestureRecognizer(target: self, action: #selector(resendCode(sender:)))
        linkeableLabel = LinkableLabel()
        linkeableLabel.addGestureRecognizer(tapCheck)
        linkeableLabel.showTextWithoutUnderline(text: conf?.translations?.data?.generales?.resendPin != nil ? "<b>\(conf!.translations!.data!.generales!.resendPin!)</b>" : "" )
        linkeableLabel.textAlignment = .center
        viewContainer.addSubview(linkeableLabel)
        nextButton = RedBorderWhiteBackgroundButton(textButton: conf?.translations?.data?.generales?.validateBtn != nil ? conf!.translations!.data!.generales!.validateBtn! : "")
        nextButton.addTarget(self, action: #selector(validateCode), for: UIControlEvents.touchUpInside)
        viewContainer.addSubview(nextButton)
        scrollView.addSubview(viewContainer)
        scrollView.frame = viewContainer.frame
        scrollView.contentSize = viewContainer.frame.size
        self.view.addSubview(scrollView)
        setupConstraints(view: viewContainer)
    }
    
    func setupConstraints(view: UIView) {
        constrain(view, headerView, codeContainer) { (view, header, container) in
            header.top == view.top
            header.leading == view.leading
            header.trailing == view.trailing
            header.height == view.height * 0.35
            
            container.top == header.bottom + 10.0
            container.centerX == view.centerX
            container.width == view.width * 0.45
            container.height == 40.0
        }
        
        
        constrain(view, codeContainer, questionLabel, linkeableLabel) { (view, container, question, label) in
            question.top == container.bottom + 20.0
            question.leading == view.leading + 31.0
            question.trailing == view.trailing - 32.0
            question.height == 16.0
            
            
            
            label.top == question.bottom + 8.0
            label.leading == view.leading + 31.0
            label.trailing == view.trailing - 31.0
            label.height == 18.0
        }
        
        constrain(view, linkeableLabel, nextButton) { (view, label, button) in
            button.top == label.bottom + 38.0
            button.leading == view.leading + 31.0
            button.trailing == view.trailing - 32.0
            button.height == 40
        }
    }
    
    
    
    /// Clase encargada de mostrar el primer paso del registro para el App Mi Claro
    override func viewDidLoad() {
        super.viewDidLoad()
        setupElements()
    }
    /// Función encargada de inicializar los números de intentos y cargarlos desde el archivo de configuración
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let gConfig = mcaManagerSession.getGeneralConfig(), let config = gConfig.config, let tryOuts = config.triesForPasswordRecovery {
            self.tryOutNumbers = tryOuts
        }
        self.initWith(navigationType: ButtonNavType.IconBack, headerTitle: conf?.translations?.data?.passwordRecovery?.header ?? "")
    }
    /// Función depreciada
    func lnkTerminos_OnClick(sender: Any) {
    }
    /// Función que setea la variable gtpRequest con el objeto GetTempPasswordRequest
    /// - parameter gtpr: GetTempPasswordRequest?
    func setGTP(gtpr : GetTempPasswordRequest?) {
        self.gtpRequest = gtpr;
    }
    /// Función que setea la variable gtpResult con el objeto GetTempPasswordResult
    /// - parameter gtprr: GetTempPasswordResult?
    func setGTPResult(gtprr : GetTempPasswordResult) {
        self.gtpResult = gtprr;
    }
    
    /// Función encargada de validar el código ingresado, de no ser correcto mostrará una alerta
    func validateCode() {
        let timeSMS = AnalyticsInteractionSingleton.sharedInstance.stopTimer()
        AnalyticsInteractionSingleton.sharedInstance.ADBTrackViewRecoveryPass(viewName: "Recuperar contrasena|Paso 3|Ingresar codigo verificacion", type: 3, detenido: false, intervalo: timeSMS)//NO
        AnalyticsInteractionSingleton.sharedInstance.ADBTrackCustomLink(viewName: "Recuperar contrasena|Paso 3|Ingresar codigo verificacion:Validar")
        
        codeContainer.resignResponder()
        if (codeContainer.getCode().count != 4) {
            
            GeneralAlerts.showAcceptOnly(text: NSLocalizedString("debes-ingresar-codigo-verificacion", comment: ""), icon: AlertIconType.IconoAlertaPregunta, onAcceptEvent: {})
            
            return;
        }
        
        
        if (gtpResult?.getTempPasswordResponse?.temporaryPassword?.lowercased() != codeContainer.getCode().lowercased()) {

            GeneralAlerts.showAcceptOnly(text: "El código no coincide", icon: AlertIconType.IconoAlertaPregunta, onAcceptEvent: {})
            
            return;
        }
        
        let req = ValidateTempPasswordRequest();
        req.validateTempPassword?.password = codeContainer.getCode();
        req.validateTempPassword?.userProfileId = gtpRequest?.getTempPassword?.userProfileId;
        req.validateTempPassword?.lineOfBusiness = "0";
        
        mcaManagerServer.executeValidateTempPassword(params: req,
                                                           onSuccess: { [req] (result) in
                                                            self.tryAttemps = 1
                                                            let rpcp = RecoverPasswordConfirmPasswordVC()
                                                            rpcp.doLoginWhenFinish = self.doLoginWhenFinish
                                                            rpcp.setVTPR(value: req);
                                                            self.navigationController?.pushViewController(rpcp, animated: true);
            },
                                                           onFailure: { (result, myError) in
                                                            if self.tryOutNumbers > self.tryAttemps {
                                                                self.tryAttemps += 1
                                                                
                                                                GeneralAlerts.showAcceptOnly(text: result?.validateTempPasswordResponse?.acknowledgementDescription ?? "", icon: AlertIconType.IconoAlertaError, onAcceptEvent: {})
                                                                
                                                            } else {
                                                                if let viewController = mcaRecoveryPasswordManager.findPasswordRecoveryVC(navigation: self.navigationController) {
                                                                    self.navigationController?.popToViewController(viewController, animated: true)
                                                                } else {
                                                                    self.navigationController?.popToRootViewController(animated: true)
                                                                }
                                                            }
        });
    }
    /// Función para el re-envío del código
    func resendCode(sender: Any) {
        mcaManagerServer.executeGetTempPassword(params: gtpRequest!,
                                                      onSuccess: { (result) in
                                                        self.tryAttempsResend = 1
                                                        self.setGTPResult(gtprr:  result.0)
                                                        //let conf = SessionSingleton.sharedInstance.getGeneralConfig();
                                                        
                                                        let msgCode = (result.0.getTempPasswordResponse?.acknowledgementDescription)!
                                                        //(conf?.translations?.data?.generales?.pinAlert)!
                                                        
                                                        GeneralAlerts.showAcceptOnly(title: self.conf?.translations?.data?.generales?.pinAlertTitle ?? "", text: msgCode, icon: .IconoFelicidadesContraseñaCambiada, acceptBtnColor: institutionalColors.claroBlueColor, buttonName: self.conf?.translations?.data?.generales?.closeBtn ?? "", onAcceptEvent: {})
        },
                                                      onFailure: { (result, myError) in
                                                        if self.tryOutNumbers > self.tryAttempsResend {
                                                            self.tryAttempsResend += 1
                                                            
                                                        } else {
                                                            if let viewController = mcaRecoveryPasswordManager.findPasswordRecoveryVC(navigation: self.navigationController) {
                                                                self.navigationController?.popToViewController(viewController, animated: true)
                                                            } else {
                                                                self.navigationController?.popToRootViewController(animated: true)
                                                            }
                                                        }
        });
    }
    /// Función para atrapar el click en una etiqueta linkeable
    func ClickedNormalText() {
        ClickedBoldText();
    }
    /// Función que realiza el trigger a la acción de una etiqueta linkeable
    func ClickedBoldText() {
        if false == mcaManagerSession.isNetworkConnected() {
            mcaManagerSession.showOfflineMessage()
            return;
        }
        
        
        GeneralAlerts.showDataWebView(title: mcaManagerSession.getGeneralConfig()?.translations?.data?.generales?.termsAndConditions ?? "",
                                      url: mcaManagerSession.getGeneralConfig()?.termsAndConditions?.url ?? "", method: "GET",
                                      acceptTitle: mcaManagerSession.getGeneralConfig()?.translations?.data?.generales?.closeBtn ?? "", onAcceptEvent: {})
        
    }
    /// Detección de touches en el screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //aun no esta entrando aqui
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let timeSMS = AnalyticsInteractionSingleton.sharedInstance.stopTimer()
        AnalyticsInteractionSingleton.sharedInstance.ADBTrackViewRecoveryPass(viewName: "Recuperar contrasena|Paso 3|Ingresar codigo verificacion", type: 3, detenido: false, intervalo: timeSMS)
    }
    
    /// Alerta de insuficiencia de memoria
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

