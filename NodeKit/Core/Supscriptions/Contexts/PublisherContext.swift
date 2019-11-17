import Foundation
import Combine

@available(iOS 13.0, *)
public class PublisherContext<O>: Publisher, Cancellable {

    public typealias Output = O
    public typealias Failure = Error

    public var publisher: AnyPublisher<O, Error>

    init<P>(publisher: P) where P: Publisher, P.Output == O, P.Failure == Error {
        self.publisher = AnyPublisher(publisher)
    }
    
    /// Лог-сообщение.
    public var log: Logable?

    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, O == S.Input {
        self.publisher.receive(subscriber: subscriber)
    }

    public func cancel() {
        fatalError()
    }

    /// Добавляет лог-сообщение к контексту.
    /// В случае, если у контекста не было лога, то он появится.
    /// В случае, если у контекста был лог, но у него не было следующего, то этот добавится в качестве следующего лога.
    /// В случае, если лог был, а у него был следующий лог, то этот будет вставлен между ними.
    ///
    /// - Parameter log: лог-сообщение.
    @discardableResult
    open func log(_ log: Logable?) -> Self {
        guard var selfLog = self.log else {
            self.log = log
            return self
        }

        if selfLog.next == nil {
            selfLog.next = log
        } else {
            var temp = log
            temp?.next = selfLog.next
            selfLog.next = temp
        }

        self.log = selfLog
        return self
    }
}

@available(iOS 13.0, *)
public extension PublisherContext {
    static func emit(error: Error) -> PublisherContext<O> {
        PublisherContext(publisher: Fail(error: error))
    }
}
