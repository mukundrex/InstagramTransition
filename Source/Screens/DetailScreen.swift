//
//  DetailScreen.swift
//  InstagramTransition
//
//  Created by Kolos Foltanyi on 2023. 07. 22..
//

import UIKit

class DetailScreen: UIViewController {

    // MARK: Private properties

    private var picture: Picture

    // MARK: UI Properties

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let header = DetailHeader(title: "Posts", userName: "USER")
    private let imageHeader = ImageHeader(userName: "user", location: "Budapest")
    private let imageView = ImageView()
    private let imageFooter = ImageFooter(date: "6 days ago")
    private lazy var recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
    private let transitionAnimator = SharedTransitionAnimator()
    
    // MARK: Public properties (for modal interaction)
    var interactionController: SharedTransitionInteractionController?

    // MARK: Init

    init(picture: Picture) {
        self.picture = picture
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure imageView has proper layout for frame calculations
        imageView.layoutIfNeeded()
    }
}

// MARK: - Setup

extension DetailScreen {
    private func setupUI() {
        setupView()
        setupHeader()
        setupScrollView()
        setupImageHeader()
        setupImageView()
        setupImageFooter()
    }

    private func setupView() {
        view.backgroundColor = .white
        view.addGestureRecognizer(recognizer)
        recognizer.delegate = self
    }

    private func setupHeader() {
        header.then {
            view.addSubview($0)
            $0.backNavigation = { [weak self] in
                self?.dismiss(animated: true)
            }
        }.layout {
            $0.top == view.safeAreaLayoutGuide.topAnchor
            $0.leading == view.leadingAnchor
            $0.trailing == view.trailingAnchor
        }
    }

    private func setupScrollView() {
        scrollView.then {
            $0.alwaysBounceVertical = true
            view.addSubview($0)
        }.layout {
            $0.top == header.bottomAnchor
            $0.leading == view.leadingAnchor
            $0.trailing == view.trailingAnchor
            $0.bottom == view.safeAreaLayoutGuide.bottomAnchor
        }

        contentView.then {
            scrollView.addSubview($0)
            scrollView.fillWith($0)
        }.layout {
            $0.width == scrollView.widthAnchor
            $0.height >= scrollView.heightAnchor
        }
    }

    private func setupImageHeader() {
        imageHeader.then {
            contentView.addSubview($0)
        }.layout {
            $0.top == contentView.topAnchor + 8
            $0.leading == view.leadingAnchor
            $0.trailing == view.trailingAnchor
        }
    }

    private func setupImageView() {
        imageView.then {
            contentView.addSubview($0)
            $0.contentMode = .scaleAspectFit
            $0.layer.masksToBounds = true
            $0.setImage(from: picture.imageURL)
        }.layout {
            $0.leading == contentView.leadingAnchor
            $0.trailing == contentView.trailingAnchor
            $0.top == imageHeader.bottomAnchor + 10
        }

        imageView.heightAnchor.constraint(
            equalTo: imageView.widthAnchor,
            multiplier: 1.25
        ).isActive = true
    }

    private func setupImageFooter() {
        imageFooter.then {
            contentView.addSubview($0)
        }.layout {
            $0.top == imageView.bottomAnchor + 10
            $0.leading == contentView.leadingAnchor
            $0.trailing == contentView.trailingAnchor
        }
    }
}

// MARK: UIGestureRecognizerDelegate

extension DetailScreen: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow simultaneous recognition with scroll view when it's bouncing
        // or when we're handling a horizontal gesture
        if scrollView.isBouncing {
            return true
        }
        
        // Check if this is a vertical gesture when scroll view is at top
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGesture.velocity(in: view)
            let isVertical = abs(velocity.y) > abs(velocity.x)
            let isScrollAtTop = scrollView.contentOffset.y <= 0
            
            // Allow simultaneous recognition for vertical gestures when scroll is at top
            if isVertical && isScrollAtTop {
                return false // Don't allow simultaneous - we want to handle the vertical drag
            }
        }
        
        return scrollView.isBouncing
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        
        let velocity = panGesture.velocity(in: view)
        let isVertical = abs(velocity.y) > abs(velocity.x)
        let isHorizontal = abs(velocity.x) > abs(velocity.y)
        
        // For vertical gestures, only allow when scroll view is at top and gesture is downward
        if isVertical {
            let isScrollAtTop = scrollView.contentOffset.y <= 0
            let isDownwardGesture = velocity.y > 0
            return isScrollAtTop && isDownwardGesture
        }
        
        // For horizontal gestures, always allow
        if isHorizontal {
            return true
        }
        
        return false
    }
}



// MARK: UIPanGestureRecognizer

extension DetailScreen {
    @objc
    func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let window = UIApplication.keyWindow!
        switch recognizer.state {
        case .began:
            let velocity = recognizer.velocity(in: window)
            let isVertical = abs(velocity.y) > abs(velocity.x)
            let isHorizontal = abs(velocity.x) > abs(velocity.y)
            
            // Determine gesture direction and validate
            if isHorizontal {
                // Existing horizontal logic
                interactionController = SharedTransitionInteractionController()
                interactionController?.gestureDirection = .horizontal
                dismiss(animated: true)
            } else if isVertical {
                // New vertical logic - only if scroll view is at top and gesture is downward
                let isScrollAtTop = scrollView.contentOffset.y <= 0
                let isDownwardGesture = velocity.y > 0
                
                if isScrollAtTop && isDownwardGesture {
                    interactionController = SharedTransitionInteractionController()
                    interactionController?.gestureDirection = .vertical
                    dismiss(animated: true)
                }
            }
        case .changed:
            interactionController?.update(recognizer)
        case .ended:
            guard let controller = interactionController else { return }
            
            let velocity = recognizer.velocity(in: window)
            let shouldFinish: Bool
            
            switch controller.gestureDirection {
            case .horizontal:
                shouldFinish = velocity.x > 0
            case .vertical:
                shouldFinish = velocity.y > 500 // Require faster downward velocity for vertical dismiss
            }
            
            if shouldFinish {
                controller.finish()
            } else {
                controller.cancel()
            }
            interactionController = nil
        default:
            interactionController?.cancel()
            interactionController = nil
        }
    }
}

// MARK: SharedTransitioning

extension DetailScreen: SharedTransitioning {
    var sharedFrame: CGRect {
        // Ensure views are laid out
        view.layoutIfNeeded()
        imageView.layoutIfNeeded()
        
        // Try multiple approaches to get a valid frame
        
        // Approach 1: Standard frameInWindow
        if let frame = imageView.frameInWindow, !frame.isEmpty {
            return frame
        }
        
        // Approach 2: Manual conversion to view controller's view
        let frameInView = imageView.convert(imageView.bounds, to: view)
        if !frameInView.isEmpty {
            return frameInView
        }
        
        // Approach 3: Use imageView's frame in its superview and convert manually
        if let contentView = imageView.superview {
            let frameInContentView = imageView.frame
            let frameInScrollView = contentView.convert(frameInContentView, to: scrollView)
            let frameInMainView = scrollView.convert(frameInScrollView, to: view)
            if !frameInMainView.isEmpty {
                return frameInMainView
            }
        }
        
        return .zero
    }
}
