//
//  HandleRequestContext.swift
//  NetworkLayer
//
//  Created by Александр Кравченков on 14.10.2017.
//  Copyright © 2017 Кравченков Александр. All rights reserved.
//

import Foundation

/// Context that incapsulate request handle
/// It may used for automatic convertion response type to awaiting type
public class HandleRequestContext<RequestModel, ResultModel>: HandableRequestContext, CancellableContext {

    // MARK: - Typealiases
					
    public typealias ResultType = ResultModel
    public typealias RequestType = RequestModel
    public typealias CompletedClosure = (ResultModel) -> Void
    public typealias HandlerClosure = (ResponseResult<RequestModel>) -> ResponseResult<ResultModel>
    public typealias ErrorClosure = (Error) -> Void

    // MARK: - Private fields

    private var completedClosure: CompletedClosure?
    private var errorClosure: ErrorClosure?
    
    private let request: BaseServerRequest<RequestModel>
    private let handler: HandlerClosure

    // MARK: - Initializers / Deinitializers

    public required init(request: BaseServerRequest<RequestModel>, handler: @escaping HandlerClosure) {
        self.request = request
        self.handler = handler
    }

    #if DEBUG

    deinit {
        print("ActiveRequestContext DEINIT")
    }

    #endif

    // MARK: - Context methods

    @discardableResult
    public func onCompleted(_ closure: @escaping CompletedClosure) -> Self {
        self.completedClosure = closure
        return self
    }

    @discardableResult
    public func onError(_ closure: @escaping ErrorClosure) -> Self {
        self.errorClosure = closure
        return self
    }

    public func perform() {
        self.request.performAsync { self.performHandler(result: $0) }
    }

    public func cancel() {
        self.request.cancel()
    }

    public func safePerform(manager: AccessSafeManager) {
        let request = ServiceSafeRequest(request: self.request) { self.performHandler(result: $0) }
        manager.addRequest(request: request)
    }

    private func performHandler(result: ResponseResult<RequestModel>) {
        let converted = self.handler(result)
        switch converted {
        case .failure(let error):
            self.errorClosure?(error)
        case .success(let value, _):
            self.completedClosure?(value)
        }
    }
}