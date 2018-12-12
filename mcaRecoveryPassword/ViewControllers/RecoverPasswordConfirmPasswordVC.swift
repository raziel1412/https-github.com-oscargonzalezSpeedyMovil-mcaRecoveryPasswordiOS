//
//  RecoverPasswordConfirmPasswordVC.swift
//  MiClaro
//
//  Created by Roberto Gutierrez Resendiz on 09/08/17.
//  Copyright © 2017 am. All rights reserved.
//

import UIKit
import Cartography
import mcaUtilsiOS
import mcaManageriOS
import mcaHomeiOS

/// Clase para mostrar la vista de confirmar passowrd
class RecoverPasswordConfirmPasswordVC: UIViewController, UITextFieldDelegate {
    
    /// ValidateTempPasswordRequest
    var vtpr : ValidateTempPasswordRequest?
    /// Etiqueta lblTitulo
    private var lblTitulo : InstructionLabel?;
    /// TextField para passwordView
    private var passwordView : UITextFieldGroup = UITextFieldGroup(frame: .zero)
    /// TextField para confirmPasswordView
    private var confirmPasswordView : UITextFieldGroup = UITextFieldGroup(frame: .zero)
    /// Botón Ingresar
    private var cmdIngresar : RedBorderWhiteBackgroundButton!
    /// Array de validaciones
    private var validationArray = [String]()
    /// Vista de validación
    //private var validationView: PasswordValContainerView!
    /// Variable de constraints
    private var grupo : ConstraintGroup?;
    /// Número de tryouts total
    private var tryOutNumbers : Int = 1
    /// Número de intentos
    private var tryAttemps : Int = 1
    
    private let conf = mcaManagerSession.getGeneralConfig()
    private var headerView : UIHeaderForm = UIHeaderForm(frame: .zero)
    private var passwordRules : PasswordRulesContainer = PasswordRulesContainer(frame: .zero)
    
    func setupElements() {
        view.backgroundColor = institutionalColors.claroWhiteColor
        self.initWith(navigationType: .IconBack, headerTitle: conf?.translations?.data?.passwordRecovery?.header ?? "")
        let scrollView = UIScrollView(frame: .zero)
        let viewContainer = UIView(frame: self.view.bounds)
        headerView.setupElements(imageName: "ico_seccion_pass", title: conf?.translations?.data?.passwordRecovery?.title, subTitle: conf?.translations?.data?.passwordRecovery?.recoveryThirdStep)
        viewContainer.addSubview(headerView)
        passwordView.setupContent(imageName: "icon_contrasena_input", text: conf?.translations?.data?.generales?.password, placeHolder: conf?.translations?.data?.generales?.password)
        passwordView.textField.delegate = self
        passwordView.textField.setupSecurityEye()
        viewContainer.addSubview(passwordView)
        confirmPasswordView.setupContent(imageName: "icon_contrasena_input", text: conf?.translations?.data?.generales?.confirmPassword, placeHolder: conf?.translations?.data?.generales?.confirmPassword)
        confirmPasswordView.textField.delegate = self
        confirmPasswordView.textField.setupSecurityEye()
        viewContainer.addSubview(confirmPasswordView)
        passwordRules.setupContent(title: conf?.translations?.data?.generales?.passwordMustHave ?? "", rules: [
            conf?.translations?.data?.generales?.passwordRule1 ?? "",
            conf?.translations?.data?.generales?.passwordRule2 ?? "",
            conf?.translations?.data?.generales?.passwordRule3 ?? ""
            ])
        viewContainer.addSubview(passwordRules)
        cmdIngresar = RedBorderWhiteBackgroundButton(textButton: conf?.translations?.data?.generales?.signBtn ?? "")
        cmdIngresar.addTarget(self, action: #selector(confirmPassword), for: UIControlEvents.touchUpInside)
        viewContainer.addSubview(cmdIngresar)
        scrollView.addSubview(viewContainer)
        scrollView.frame = viewContainer.frame
        scrollView.contentSize = viewContainer.frame.size
        self.view.addSubview(scrollView)
        setupConstraints(view: viewContainer)
    }
    
    func setupConstraints(view: UIView) {
        constrain(view, headerView, passwordView, confirmPasswordView) { (parent, header, password, confirm) in
            header.top == parent.top
            header.leading == parent.leading
            header.trailing == parent.trailing
            header.height == parent.height * 0.35
            
            password.top == header.bottom + 16.0
            password.leading == parent.leading + 32.0
            password.trailing == parent.trailing - 31.0
            password.height == 60.0
            
            confirm.top == password.bottom + 16.0
            confirm.leading == parent.leading + 32.0
            confirm.trailing == parent.trailing - 31.0
            confirm.height == 60.0
        }
        
        constrain(view, confirmPasswordView.textField, passwordRules ,cmdIngresar) { (parent, confirm, rules, button) in
            rules.leading == confirm.leading
            rules.trailing == parent.trailing - 31.0
            rules.height == 65.0
            rules.top == confirm.bottom + 20.0
            
            button.top == rules.bottom + 16.0
            button.leading == parent.leading + 32.0
            button.trailing == parent.trailing - 31.0
            button.height == 40.0
        }
        
    }
    
    
    /// Función carga de los elementos gráficos, constraints y variables
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupElements()
        
    }
    
    /// Función ejecutada al momento que la vista es llamada antes aparecer
    override func viewWillAppear(_ animated: Bool) {
        if let gConfig = mcaManagerSession.getGeneralConfig(), let config = gConfig.config, let tryOuts = config.triesForPasswordRecovery {
            self.tryOutNumbers = tryOuts
        }
        
         AnalyticsInteractionSingleton.sharedInstance.ADBTrackViewRecoveryPass(viewName: "Recuperar contrasena|Paso 4|Ingresar nueva contrasena",type:4, detenido: false)
    }
    
    /// Setter ValidateTempPasswordRequest
    func setVTPR(value : ValidateTempPasswordRequest?) {
        self.vtpr = value;
    }
    
    
    /// Función validar confirmPassword y llama al servicio web executeUpdatePassword
    func confirmPassword() {
        AnalyticsInteractionSingleton.sharedInstance.ADBTrackCustomLink(viewName: "Recuperar contrasena|Paso 4|Ingresar nueva contrasena:Confirmar")
        
        if passwordView.textField.canResignFirstResponder {
            passwordView.textField.resignFirstResponder();
        }

        if confirmPasswordView.textField.canResignFirstResponder {
            confirmPasswordView.textField.resignFirstResponder();
        }
        
        
        if ("" == passwordView.textField.text || "" == confirmPasswordView.textField.text) {
            if ("" == passwordView.textField.text) {
                passwordView.mandatoryInformation.displayView(customString: conf?.translations?.data?.generales?.emptyField ?? "")
            } else {
                passwordView.mandatoryInformation.hideView()
            }
            if ("" == confirmPasswordView.textField.text) {
                confirmPasswordView.mandatoryInformation.displayView(customString: conf?.translations?.data?.generales?.emptyField ?? "")
            } else {
                confirmPasswordView.mandatoryInformation.hideView()
            }
            return
        }
        if (passwordView.textField.text == confirmPasswordView.textField.text) {
            let req = UpdatePasswordRequest();
            req.updatePassword?.userProfileId = vtpr?.validateTempPassword?.userProfileId;
            req.updatePassword?.lineOfBusiness = "0";
            req.updatePassword?.password = passwordView.textField.text;
            mcaManagerServer.executeUpdatePassword(params: req,
                                                         onSuccess: { (result) in
                                                           let onAcceptEvent = {
                                                            self.navigationController?.popToRootViewController(animated: true)
                                                            AnalyticsInteractionSingleton.sharedInstance.ADBTrackCustomLink(viewName: "Recuperar contrasena|Exito:Cerrar")
                                                            }
                                                            
                                                            GeneralAlerts.showAcceptOnly(title: self.conf?.translations?.data?.passwordRecovery?.recoverySuccessTitle ?? "¡Cambio de Contraseña Exitoso!", text: result.0.updatePasswordResponse?.acknowledgementDescription ?? "", icon: .IconoFelicidadesContraseñaCambiada, acceptBtnColor: institutionalColors.claroBlueColor, buttonName: self.conf?.translations?.data?.generales?.closeBtn ?? "", onAcceptEvent: onAcceptEvent)
                                                            
                                                             AnalyticsInteractionSingleton.sharedInstance.ADBTrackViewRecoveryPass(viewName: "Recuperar contrasena|Exito",type:5, detenido: false)
                                                            
            },
                                                         onFailure: { (result, myError) in
                                                            /******************************************/
                                                            GeneralAlerts.showAcceptOnly(text: result?.updatePasswordResponse?.acknowledgementDescription ?? "", icon: .IconoAlertaError, onAcceptEvent: {})
                                                            /******************************************/
                                                            
                                                            if self.tryOutNumbers > self.tryAttemps {
                                                                self.tryAttemps += 1
                                                                
                                                            } else {
                                                                if let viewController = mcaRecoveryPasswordManager.findPasswordRecoveryVC(navigation: self.navigationController) {
                                                                    self.navigationController?.popToViewController(viewController, animated: true)
                                                                } else {
                                                                    self.navigationController?.popToRootViewController(animated: true)
                                                                }
                                                            }
            })
        } else {
            confirmPasswordView.mandatoryInformation.displayView(customString: conf?.translations?.data?.generales?.passwordSameError)
        }
    }

    /// Función que es llamada luego de hacer el recovery exitosamente, encargada para realizar el login
    func automaticLogin() {
        let req = RetrieveProfileInformationRequest();
        req.retrieveProfileInformation?.lineOfBusiness = "0";
        req.retrieveProfileInformation?.userProfileId = vtpr?.validateTempPassword?.userProfileId

        mcaManagerServer.executeRetrieveProfileInformation(lineOfBusiness: "0", userProfileId: vtpr?.validateTempPassword?.userProfileId ?? "",
                                                                 onSuccess: { (result) in
                                                                    print(result);
                                                                    DispatchQueue.main.async(execute: {
                                                                        UIApplication.shared.keyWindow?.rootViewController  = HomeVC()
                                                                    })
        },
                                                                 onFailure: { (result, myError) in
                                                                    
                                                                    GeneralAlerts.showAcceptOnly(title: "404-response-profile-information", icon: .IconoAlertaError, onAcceptEvent: {})

        });
    }

    /// Touches began
    /// - parameters touches: Set<UITouch>
    /// - parameters event: UIEvent
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    /// Alerta insuficiencia de memoria
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// función para validación del password
    /// - parameter pass: String
    func validate(pass : String) -> (hasError : Bool, errorString : String?){
        
        let numberRegEx  = ".*[0-9]+.*"
        let texttest1 = NSPredicate(format:"SELF MATCHES %@", numberRegEx)
        let numberresult = texttest1.evaluate(with: pass)
        if !numberresult {
            //"passwordRuleError": "El formato de la contraseña es incorrecto.",
            return (true, conf?.translations?.data?.generales?.passwordRuleError)
        }
        
        let letterRegEx  = ".*[a-z]+.*"
        let texttest = NSPredicate(format:"SELF MATCHES %@", letterRegEx)
        let letterresult = texttest.evaluate(with: pass.lowercased())
        if !letterresult {
            //"passwordRuleError": "El formato de la contraseña es incorrecto.",
            return (true, conf?.translations?.data?.generales?.passwordRuleError)
        }
        
        let specialCharacterRegEx  = ".*[*^'-]+.*"
        let texttest2 = NSPredicate(format:"SELF MATCHES %@", specialCharacterRegEx)
        let specialresult = texttest2.evaluate(with: pass)
        if specialresult {
            //"passwordRuleError": "El formato de la contraseña es incorrecto.",
            return (true, conf?.translations?.data?.generales?.passwordRuleError)
        }
        
        return (false, nil)
        //"passwordSameError": "La contraseña no coincide.",
        
        
    }
    
    /// Textfield delegate textFieldDidBeginEditing
    /// - parameter textField: UITextField
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    /// Función que permite determinar si el texto ingresado son caracteres validos y modifica / agrega / Elimina o no el caracter
    /// - parameter textField: campo de texto que se está editando
    /// - parameter range: Rango de los caracteres
    /// - parameter string: Cadena a anexar
    /// - Returns: Bool
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
         guard let text = textField.text else { return true }
        
        let newLength = text.count + string.count - range.length
        if (passwordView.textField == textField) {
            if newLength == 0 {
                passwordView.mandatoryInformation.displayView()
            } else {
                let str = textField.text! as NSString
                let cad = str.replacingCharacters(in: range, with: string)
                let validateResult = self.validate(pass: cad);
                if validateResult.hasError == true {
                    passwordView.mandatoryInformation.displayView(customString: validateResult.errorString)
                } else {
                    passwordView.mandatoryInformation.hideView()
                }
            }
        }
        
        if (confirmPasswordView.textField == textField) {
            if newLength == 0 {
                confirmPasswordView.mandatoryInformation.displayView()
            } else {
                let str = textField.text! as NSString
                let cad = str.replacingCharacters(in: range, with: string)
                let validateResult = self.validate(pass: cad);
                if validateResult.hasError == true {
                    confirmPasswordView.mandatoryInformation.displayView(customString: validateResult.errorString)
                } else {
                    confirmPasswordView.mandatoryInformation.hideView()
                }
            }
        }
        
        
        return newLength <= 12 // Bool
        
    }
}
