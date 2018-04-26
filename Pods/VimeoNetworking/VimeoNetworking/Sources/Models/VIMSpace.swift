//
//  VIMSpace.swift
//  VimeoNetworking
//
//  Created by Lim, Jennifer on 4/3/18.
//

public class VIMSpace: VIMSizeQuota
{
    /// Whether the values of the upload_quota.space fields are for the lifetime quota or the periodic quota. Values can be `lifetime` or `periodic`.
    @objc dynamic public private(set) var type: String?
    
    // MARK: - VIMMappable
    
    public override func getObjectMapping() -> Any
    {
        return ["showing" : "type"]
    }
}
