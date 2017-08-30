import UIKit

public class ContainerView: UIView {
    required public init(_ subview: UIView) {
        let screen = UIScreen.main.bounds
        
        super.init(frame: screen)
        
        self.backgroundColor = UIColor.white
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.addSubview(subview)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-(margin)-[subview]-(margin)-|",
                                                           options: [],
                                                           metrics: ["margin": 30.0],
                                                           views: ["subview": subview]))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: subview, attribute: .centerY,
                                              multiplier: 1.0, constant: 0.0))
        self.setNeedsUpdateConstraints()
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
