import AVFoundation
import AVKit

class ViewController: UIViewController {
  var captureSession: AVCaptureSession?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var audioEngine: AVAudioEngine?
  var audioPicker: AVRoutePickerView?
  
  enum AudioSessionPortDescriptionUID: String {
    case WiredMicrophone = "Wired Microphone"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    UIApplication.shared.isIdleTimerDisabled = true
    
  }
  
  override func viewWillAppear(_: Bool) {
    let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
    tap.numberOfTapsRequired = 2
    view.addGestureRecognizer(tap)
    
    let videoDevice = AVCaptureDevice.default(for: .video)
    
    do {
      try resetAudioSession()
      resetAudioEngine()
      
      try AVAudioSession.sharedInstance().setActive(true)
      try audioEngine!.start()
      
      let videoInput = try AVCaptureDeviceInput(device: videoDevice!)
      
      captureSession = AVCaptureSession()
      captureSession?.beginConfiguration()
      captureSession?.sessionPreset = .hd1920x1080
      captureSession?.addInput(videoInput)
      
      videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
      videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
      
      view.layer.addSublayer(videoPreviewLayer!)
      
      let orientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation) ?? .landscapeRight
      videoPreviewLayer?.connection?.videoOrientation = orientation
      
      captureSession?.commitConfiguration()
      captureSession?.startRunning()
    } catch {
      print(error)
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    audioPicker = AVRoutePickerView(frame: view.layer.bounds)
    view.addSubview(audioPicker!)
    audioPicker!.isHidden = true
    
    super.viewDidAppear(animated)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    videoPreviewLayer?.frame = view.layer.bounds
  }
  
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    coordinator.animate(alongsideTransition: { _ in
      UIView.setAnimationsEnabled(true)
    }) { [weak self] _ in
      self?.videoPreviewLayer?.connection?.videoOrientation = UIDevice.current.orientation == .landscapeLeft ? .landscapeRight : .landscapeLeft
    }
    
    UIView.setAnimationsEnabled(false)
  }
  
  private func resetAudioSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .allowAirPlay, .allowBluetoothA2DP])
    try session.setPreferredInput(session.availableInputs?.first(where: { (description) -> Bool in
      description.uid == AudioSessionPortDescriptionUID.WiredMicrophone.rawValue
    }))
  }
  
  private func resetAudioEngine() {
    if let audioEngine = audioEngine {
      audioEngine.stop()
      self.audioEngine = nil
    }
    
    let audioEngine = AVAudioEngine()
    audioEngine.connect(audioEngine.inputNode, to: audioEngine.mainMixerNode, format: nil)
    audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: nil)
    self.audioEngine = audioEngine
  }
  
  @objc func doubleTapped() {
    let button = audioPicker!.subviews.first(where: { $0 is UIButton }) as? UIButton
    button?.sendActions(for: .touchUpInside)
  }
}

extension AVCaptureVideoOrientation {
  init?(deviceOrientation: UIDeviceOrientation) {
    print(deviceOrientation.rawValue)
    switch deviceOrientation {
    case .portrait: self = .portrait
    case .portraitUpsideDown: self = .portraitUpsideDown
    case .landscapeLeft: self = .landscapeRight
    case .landscapeRight: self = .landscapeLeft
    default: return nil
    }
  }
  
  init?(interfaceOrientation: UIInterfaceOrientation) {
    switch interfaceOrientation {
    case .portrait: self = .portrait
    case .portraitUpsideDown: self = .portraitUpsideDown
    case .landscapeLeft: self = .landscapeLeft
    case .landscapeRight: self = .landscapeRight
    default: return nil
    }
  }
}
