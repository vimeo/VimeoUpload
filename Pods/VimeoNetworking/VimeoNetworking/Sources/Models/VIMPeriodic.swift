//
//  VIMPeriodic.swift
//  VimeoNetworking
//
//  Created by Lim, Jennifer on 4/3/18.
//

public class VIMPeriodic: VIMSizeQuota
{
    /// The time in ISO 8601 format when your upload quota resets.
    @objc dynamic public private(set) var resetDate: NSDate?
    
    // MARK: - VIMMappable
    
    public override func getObjectMapping() -> Any
    {
        return ["reset_date" : "resetDate"]
    }
}
