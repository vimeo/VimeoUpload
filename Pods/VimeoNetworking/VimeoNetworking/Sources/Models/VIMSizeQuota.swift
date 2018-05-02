//
//  VIMSizeQuota.swift
//  VimeoNetworking
//
//  Created by Lim, Jennifer on 4/3/18.
//

public class VIMSizeQuota: VIMModelObject
{
    /// Indicates the free space size
    @objc dynamic public private(set) var free: NSNumber?

    /// Indicates the maximum size quota
    @objc dynamic public private(set) var max: NSNumber?

    /// Indicates the used size quota
    @objc dynamic public private(set) var used: NSNumber?
}
