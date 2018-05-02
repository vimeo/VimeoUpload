//
//  VIMUploadQuota.swift
//  VimeoNetworking
//
//  Created by Lim, Jennifer on 3/26/18.
//

import Foundation

public class VIMUploadQuota: VIMModelObject
{
    /// The values within `VIMSpace` reflect the lowest of lifetime or period for free and max.
    @objc dynamic public private(set) var space: VIMSpace?
    
    /// Represents the current quota period
    @objc dynamic public private(set) var periodic: VIMPeriodic?
    
    /// Represents the lifetime quota period
    @objc dynamic public private(set) var lifetime: VIMSizeQuota?
    
    public override func getClassForObjectKey(_ key: String!) -> AnyClass!
    {
        if key == "space"
        {
            return VIMSpace.self
        }
        else if key == "periodic"
        {
            return VIMPeriodic.self
        }
        else if key == "lifetime"
        {
            return VIMSizeQuota.self
        }
        
        return nil
    }

    /// Determines whether the user has a periodic storage quota limit or has a lifetime upload quota storage limit only.
    @objc public lazy var isPeriodicQuota: Bool = {
        return self.space?.type == "periodic"
    }()
}
