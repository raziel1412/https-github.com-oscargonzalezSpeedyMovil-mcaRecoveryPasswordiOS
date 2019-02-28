//
//  RecoveryPasswordVC.swift
//  mcaRecoveryPassword
//
//  Created by Pilar del Rosario Prospero Zeferino on 12/3/18.
//  Copyright © 2018 Speedy Movil. All rights reserved.
//

import UIKit
import mcaManageriOS
import mcaUtilsiOS
import Cartography
import SkyFloatingLabelTextField

class RecoveryPasswordVC: UIViewController, UITextFieldDelegate, LinkeableEventDelegate {
    
    var doLoginWhenFinish :((_ doAutomaticLogin: Bool) -> Void) = {_ in }
    
    public func ClickedBoldText() {
    }
    
    public func ClickedNormalText() {
    }
    
    var homeVC: UIViewController?
    var doAutomaticLogin: Bool = false
    
    private let conf = mcaManagerSession.getGeneralConfig()
    private var nextBtn: RedBorderWhiteBackgroundButton!
    private var txtRUT : UITextFieldGroup = UITextFieldGroup(frame: .zero)
    private var lbOlvidasteMail : LinkableLabel?;
    private var termsAndConditions : TermsAndConditions = TermsAndConditions(frame: .zero)
    private var headerView : UIHeaderForm = UIHeaderForm(frame: .zero)
    private var lblTextDescription : UILabel = UILabel(frame: .zero)
    
    private let maxText = (mcaManagerSession.getGeneralConfig()?.country?.userProfileIdConfig?.max ?? 10) - 1  //10
    private let minText = (mcaManagerSession.getGeneralConfig()?.country?.userProfileIdConfig?.min ?? 8) - 1 //10
    
    func setupElements() {
        self.view.backgroundColor = institutionalColors.claroWhiteColor
        let scrollView = UIScrollView(frame: .zero)
        let viewContainer = UIView(frame: self.view.bounds)
        headerView.setupElements(imageName: "ico_seccion_pass", title: conf?.translations?.data?.passwordRecovery?.title, subTitle: conf?.translations?.data?.passwordRecovery?.recoveryFirstStep)
        viewContainer.addSubview(headerView)
        txtRUT.setupContent(imageName: "icon_rut_input", text: conf?.translations?.data?.passwordRecovery?.RUT, placeHolder: conf?.translations?.data?.passwordRecovery?.RUT)
        txtRUT.textField.delegate = self
        txtRUT.textField.autocapitalizationType = UITextAutocapitalizationType.allCharacters
        txtRUT.textField.font = UIFont(name: RobotoFontName.RobotoRegular.rawValue, size: CGFloat(14))
        txtRUT.textField.keyboardType = .default
        txtRUT.textField.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        if self.view.frame.size.width == 320 {
            txtRUT.changeFont(font: UIFont(name: RobotoFontName.RobotoRegular.rawValue, size: CGFloat(12))!)
        }
        viewContainer.addSubview(txtRUT)
        lblTextDescription.text = conf?.translations?.data?.passwordRecovery?.rutHint
        lblTextDescription.font = UIFont(name: RobotoFontName.RobotoRegular.rawValue, size: CGFloat(12))
        lblTextDescription.numberOfLines = 0
        viewContainer.addSubview(lblTextDescription)
        nextBtn = RedBorderWhiteBackgroundButton(textButton: (conf?.translations?.data?.generales?.nextBtn)!)
        nextBtn.layer.borderColor = institutionalColors.claroLightGrayColor.cgColor
        nextBtn.setTitleColor(institutionalColors.claroLightGrayColor, for: UIControlState.normal)
        nextBtn.alpha = 0.5
        nextBtn.addTarget(self, action: #selector(nextRecovery), for: .touchUpInside)
        viewContainer.addSubview(nextBtn)
        let parte1 = conf?.translations?.data?.registro?.registerTyCFirst ?? "";
        let parte2 = conf?.translations?.data?.generales?.termsAndConditions ?? "";
        let parte3 = conf?.translations?.data?.registro?.registerTyCFinal ?? "";
        let strTerminosYCondiciones = String(format: "%@ <b>%@</b> %@", parte1, parte2, parte3);
        termsAndConditions.setContent(strTerminosYCondiciones, url: mcaManagerSession.getGeneralConfig()?.termsAndConditions?.url ?? "", title: mcaManagerSession.getGeneralConfig()?.translations?.data?.generales?.termsAndConditions ?? "", acceptTitle: mcaManagerSession.getGeneralConfig()?.translations?.data?.generales?.closeBtn ?? "", offlineAction: {
            mcaManagerSession.showOfflineMessage()
        })
        
        termsAndConditions.checkBox.addTarget(self, action: #selector(habilitarRecuperar), for: .touchUpInside)
        viewContainer.addSubview(termsAndConditions)
        scrollView.addSubview(viewContainer)
        scrollView.frame = viewContainer.frame
        scrollView.contentSize = viewContainer.frame.size
        self.view.addSubview(scrollView)
        setupConstraints(view: viewContainer)
    }
    
    func setupConstraints(view: UIView) {
        constrain(view, headerView) { (parent, header) in
            header.top == parent.top
            header.leading == parent.leading
            header.trailing == parent.trailing
            header.height == parent.height * 0.35
        }
        
        constrain(view, headerView, txtRUT) { (parent, header, text) in
            text.top == header.bottom + 16.0
            text.leading == parent.leading + 32.0
            text.trailing == parent.trailing - 31.0
            text.height == 60.0
        }
        
        constrain(view, txtRUT, lblTextDescription, txtRUT.textField ) { (parent, label, guideLabel, textField) in
            guideLabel.top == label.bottom + 16.0
            guideLabel.leading == textField.leading
            guideLabel.trailing == parent.trailing - 31.0
            guideLabel.height == 30.0
        }
        
        constrain(view, lblTextDescription, termsAndConditions) { (parent, label, terms) in
            terms.top == label.bottom + 16.0
            terms.leading == parent.leading + 32.0
            terms.trailing == parent.trailing - 31.0
            terms.height == 40.0
        }
        
        constrain(view, termsAndConditions, nextBtn) { (parent, terms, button) in
            button.top == terms.bottom + 16.0
            button.leading == parent.leading + 32.0
            button.trailing == parent.trailing - 31.0
            button.height == 40.0
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupElements()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        self.initWith(navigationType: .IconBack, headerTitle: conf?.translations?.data?.passwordRecovery?.header ?? "")
        
        AnalyticsInteractionSingleton.sharedInstance.ADBTrackViewRecoveryPass(viewName: "Recuperar contrasena|Paso 1|Ingresar RUT",type:1, detenido: false)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == txtRUT.textField {
            textField.keyboardType = .asciiCapable
            if let currentText = textField.text, let separator = mcaManagerSession.getGeneralConfig()?.country?.userProfileIdConfig?.separador {
                if(currentText as NSString).length >= maxText {
                    textField.text = currentText.replacingOccurrences(of: separator, with: "")
                }
            }
            self.habilitarRecuperar()
        }
    }
    private func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        self.habilitarRecuperar()
        return true
    }
    
    private func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == txtRUT.textField {
            self.habilitarRecuperar()
        }
        
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string) as String
        let nsString = NSString(string: newString)
        
        if nsString.length > maxText {
            return false
        }
        return true
    }
    
    private func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.habilitarRecuperar()
        return true
    }
    
    
    private func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == txtRUT.textField {
            let IdentificationNumber = txtRUT.textField.text!
            let maskedString = IdentificationNumber.enmascararRut()
            if (txtRUT.textField.text! as NSString).length >= minText{
                txtRUT.textField.text = maskedString.maskedString
            }
            if let errorString = maskedString.errorString {
                txtRUT.mandatoryInformation.displayView(customString: errorString)
            }
            else{
                txtRUT.mandatoryInformation.hideView()
                var currentText = txtRUT.textField.text!
                let separator = mcaManagerSession.getGeneralConfig()?.country?.userProfileIdConfig?.separador
                currentText = currentText.replacingOccurrences(of: separator!, with: "")
                if((currentText as NSString).length >= maxText){
                    self.habilitarRecuperar()
                }
                
            }
        }
    }
    
    func nextRecovery() {
        AnalyticsInteractionSingleton.sharedInstance.ADBTrackCustomLink(viewName: "Recuperar contrasena|Paso 1|Ingresar RUT:Continuar")
        
        if txtRUT.textField.canResignFirstResponder {
            txtRUT.textField.resignFirstResponder();
        }
        
        if (true == self.txtRUT.textField.text!.isEmpty) {
            txtRUT.mandatoryInformation.displayView(customString: conf?.translations?.data?.generales?.emptyField)
            AnalyticsInteractionSingleton.sharedInstance.ADBTrackViewRecoveryPass(viewName: "Recuperar contrasena|Paso 1|Ingresar RUT|Detenido",type:1, detenido: true, mensaje: conf?.translations?.data?.generales?.emptyField)
            return;
        }
        
        if false == mcaManagerSession.isNetworkConnected() {
            mcaManagerSession.showOfflineMessage()
        }
        
        if let errorString = self.txtRUT.textField.text?.enmascararRut().errorString {
            txtRUT.mandatoryInformation.displayView(customString: errorString)
            AnalyticsInteractionSingleton.sharedInstance.ADBTrackViewRecoveryPass(viewName: "Recuperar contrasena|Paso 1|Ingresar RUT|Detenido",type:1, detenido: true, mensaje: errorString)
            return
        }
        
        if termsAndConditions.isChecked == false {
            return
        }
        
        let passwordReq = RetrieveProfileInformationRequest();
        passwordReq.retrieveProfileInformation?.lineOfBusiness = "0";
        passwordReq.retrieveProfileInformation?.userProfileId = self.txtRUT.textField.text!//.enmascararRut();
        
        var userEmail = ""
        var userPhone = ""
        
        let req = GetTempPasswordRequest()
        req.getTempPassword?.userProfileId = txtRUT.textField.text!//.enmascararRut();
        req.getTempPassword?.lineOfBusiness = "0";
        mcaManagerServer.executeGetTempPassword(params: req,
                        onSuccess: { [req] (result : GetTempPasswordResult, resultType : ResultType) in
                                let msgCode = self.conf?.translations?.data?.generales?.pinAlert ?? "PIN"
                                                        
                                mcaManagerServer.executeRetrieveProfileInformation(params: passwordReq,
                                                onSuccess: {(resultRPI, resultType) in
                                                                                                                    
                                                    userEmail = resultRPI.retrieveProfileInformationResponse?.contactMethods?[safe:0]?.emailContactMethodDetail?.emailAddress ?? ""
                                                                                                                    
                                                    userPhone = resultRPI.retrieveProfileInformationResponse?.contactMethods?[safe:0]?.mobileContactMethodDetail?.mobileNumber ?? ""
                                                                                                                 
                                                    let onAcceptEvent = {
                                                        let vcRecovery = CodeRecoveryPasswordVC()
                                                        //IMPORTANTE ISAI Verificar la siguiente linea si va o no
//                                                        vcRecovery.doLoginWhenFinish = self.doLoginWhenFinish
                                                        vcRecovery.setGTP(gtpr: req);
                                                        vcRecovery.setGTPResult(gtprr: result);
                                                        
                                                        self.navigationController?.setNavigationBarHidden(false, animated: true)
                                                        
                                                        self.navigationController?.pushViewController(vcRecovery, animated: true)
                                                        
                                                        AnalyticsInteractionSingleton.sharedInstance.ADBTrackCustomLink(viewName: "Recuperar contrasena|Paso 2|Mensaje enviado:Cerrar")
                                                    }
                                                                                                    
                                                    GeneralAlerts.showAcceptOnlyPassword(title:  self.conf?.translations?.data?.generales?.pinAlertTitle ?? "", text: msgCode, userEmail: userEmail.maskAsEmail(), userPhone: userPhone.maskAsPhone(), acceptTitle: self.conf?.translations?.data?.generales?.closeBtn ?? "", icon: .IconoCodigoDeVerificacionDeTexto, acceptColorBtn: institutionalColors.claroBlueColor, onAcceptEvent: onAcceptEvent)
                                                                                                                   
                                                    
                                                    //traer la informacion de alerta crear registros en entidades
                                                    //se procede a borrar
                                                    mcaManagerSession.clearCacheData() //self.appDelegate.killEntities()
                                                                                                                    
                                                    AnalyticsInteractionSingleton.sharedInstance.ADBTrackViewRecoveryPass(viewName: "Recuperar contrasena|Paso 2|Mensaje enviado",type:2, detenido: false)
                                                    
                                                    AnalyticsInteractionSingleton.sharedInstance.initTimer()
                                                                                                                    
                                                }, onFailure: {(result, error) in
                                                            //            let alertInfo = AlertAcceptOnly()
                                                            //            alertInfo.acceptTitle = self.conf?.translations?.data?.generales?.closeBtn ?? ""
                                                            //            alertInfo.text = (result?.retrieveProfileInformationResponse?.acknowledgementDescription?.description)!
                                                            //            alertInfo.icon = AlertIconType.IconoAlertaError
                                                            //            alertInfo.onAcceptEvent = {}
                                                            //            NotificationCenter.default.post(name: Observers.ObserverList.AcceptOnlyAlert.name,
                                                            //                                            object: alertInfo)
                                                            print("Entro a FALLA ISAI")
                                                })
        
                            },
                            onFailure: { (result, myError) in
                                    GeneralAlerts.showAcceptOnly(text: result?.getTempPasswordResponse?.acknowledgementDescription ?? "", icon: AlertIconType.IconoAlertaError, acceptTitle: self.conf?.translations?.data?.generales?.closeBtn ?? "", onAcceptEvent: {})
                                                        
                            });
    
    }
    
    func habilitarRecuperar() {
        let newString = (txtRUT.textField.text! as NSString)
        
        if (termsAndConditions.isChecked == true && newString.length >= minText){
            nextBtn.layer.borderColor = institutionalColors.claroRedColor.cgColor
            nextBtn.setTitleColor(institutionalColors.claroRedColor, for: UIControlState.normal)
            nextBtn.alpha = 1.0
            nextBtn.isEnabled = true
        }
        else{
            nextBtn.layer.borderColor = institutionalColors.claroLightGrayColor.cgColor
            nextBtn.setTitleColor(institutionalColors.claroLightGrayColor, for: UIControlState.normal)
            nextBtn.alpha = 0.5
            nextBtn.isEnabled = false
        }
    }
    
    func olvidasteMailService(_sender : Any) {
    }
    
    
    
}

