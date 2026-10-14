import Darwin
import Foundation

/// Reads the live process table through `sysctl` and `libproc`.
public enum ProcessTable {
    public static func snapshot() -> [ProcessRecord] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        let stride = MemoryLayout<kinfo_proc>.stride

        for _ in 0..<3 {
            var size = 0
            guard sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) == 0 else {
                return []
            }

            // Leave room for processes started between the two calls.
            var infos = [kinfo_proc](repeating: kinfo_proc(), count: size / stride + 32)
            size = infos.count * stride

            if sysctl(&mib, u_int(mib.count), &infos, &size, nil, 0) == 0 {
                return infos.prefix(size / stride).map(record(from:))
            }

            guard errno == ENOMEM else {
                return []
            }
        }

        return []
    }

    public static func arguments(of pid: Int32) -> [String] {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) == 0, size > 0 else {
            return []
        }

        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, u_int(mib.count), &buffer, &size, nil, 0) == 0 else {
            return []
        }

        return parseProcessArguments(Array(buffer.prefix(size)))
    }

    /// Parses a `KERN_PROCARGS2` buffer: argc, the executable path, padding,
    /// then argc null-terminated arguments.
    static func parseProcessArguments(_ buffer: [UInt8]) -> [String] {
        guard buffer.count >= 4 else {
            return []
        }

        let argumentCount = buffer.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
        var index = 4

        while index < buffer.count, buffer[index] != 0 {
            index += 1
        }
        while index < buffer.count, buffer[index] == 0 {
            index += 1
        }

        var arguments: [String] = []
        while arguments.count < argumentCount, index < buffer.count {
            let end = buffer[index...].firstIndex(of: 0) ?? buffer.count
            arguments.append(String(decoding: buffer[index..<end], as: UTF8.self))
            index = end + 1
        }

        return arguments
    }

    public static func workingDirectory(of pid: Int32) -> String? {
        var info = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, size) == size else {
            return nil
        }

        let path = withUnsafeBytes(of: info.pvi_cdir.vip_path) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
        return path.isEmpty ? nil : path
    }

    public static func residentMemory(of pid: Int32) -> UInt64 {
        var info = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size) == size else {
            return 0
        }

        return info.pti_resident_size
    }

    private static func record(from info: kinfo_proc) -> ProcessRecord {
        let name = withUnsafeBytes(of: info.kp_proc.p_comm) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
        let startTime = info.kp_proc.p_un.__p_starttime
        let device = info.kp_eproc.e_tdev

        return ProcessRecord(
            pid: info.kp_proc.p_pid,
            parentPID: info.kp_eproc.e_ppid,
            processGroupID: info.kp_eproc.e_pgid,
            terminalProcessGroupID: info.kp_eproc.e_tpgid,
            userID: info.kp_eproc.e_ucred.cr_uid,
            terminal: terminalName(for: device),
            name: name,
            startDate: Date(
                timeIntervalSince1970: TimeInterval(startTime.tv_sec)
                    + TimeInterval(startTime.tv_usec) / 1_000_000
            )
        )
    }

    private static func terminalName(for device: dev_t) -> String? {
        guard device != -1, let name = devname(device, S_IFCHR) else {
            return nil
        }

        let terminal = String(cString: name)
        return terminal == "??" ? nil : terminal
    }
}
