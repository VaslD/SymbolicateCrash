# Symbolicate Crash

You have:

```
Thread 0 name:   Dispatch queue: com.apple.main-thread
Thread 0 Crashed:
0   libsystem_kernel.dylib        	       0x20e5d8aa8 mach_msg2_trap + 8
1   libsystem_kernel.dylib        	       0x20e5eafc4 mach_msg2_internal + 80
2   libsystem_kernel.dylib        	       0x20e5eb204 mach_msg_overwrite + 388
3   libsystem_kernel.dylib        	       0x20e5d8fec mach_msg + 24
4   CoreFoundation                	       0x1d0cdead4 __CFRunLoopServiceMachPort + 160
5   CoreFoundation                	       0x1d0cdfd18 __CFRunLoopRun + 1232
6   CoreFoundation                	       0x1d0ce4ec0 CFRunLoopRunSpecific + 612
7   GraphicsServices              	       0x20ad3b368 GSEventRunModal + 164
8   UIKitCore                     	       0x1d31da86c -[UIApplication _run] + 888
9   UIKitCore                     	       0x1d31da4d0 UIApplicationMain + 340
10  PhotosMigrator              	       0x10f6bdc80 0x10f560000 + 1432704
11  dyld                          	       0x1ef506960 start + 2528

Thread 1 name:   Dispatch queue: TS_touch.analysis.queue
Thread 1:
0   libsystem_kernel.dylib        	       0x20e5d8f68 __semwait_signal + 8
1   libsystem_c.dylib             	       0x1d82c97d8 nanosleep + 220
2   Foundation                    	       0x1cb09f960 +[NSThread sleepForTimeInterval:] + 160
3   PhotosMigrator              	       0x10f6bed34 0x10f560000 + 1436980
4   libdispatch.dylib             	       0x1d827f4b4 _dispatch_call_block_and_release + 32
5   libdispatch.dylib             	       0x1d8280fdc _dispatch_client_callout + 20
6   libdispatch.dylib             	       0x1d828446c _dispatch_continuation_pop + 504
7   libdispatch.dylib             	       0x1d8283ad4 _dispatch_async_redirect_invoke + 584
8   libdispatch.dylib             	       0x1d8292a6c _dispatch_root_queue_drain + 396
9   libdispatch.dylib             	       0x1d8293284 _dispatch_worker_thread2 + 164
10  libsystem_pthread.dylib       	       0x21ecf5dbc _pthread_wqthread + 228
11  libsystem_pthread.dylib       	       0x21ecf5b98 start_wqthread + 8

...
```

You need:

```
➜  2023-03-22 exa --tree --level=2
.
└── Photos Migrator 3-22-23, 22.56.xcarchive
   ├── dSYMs
   ├── Info.plist
   ├── Products
   └── SCMBlueprint
```

You run:

```bash
# mint install VaslD/SymbolicateCrash

symbolicate-crash \
  "/Users/vasld/Library/Developer/Xcode/Archives/2023-03-22/Photos Migrator 3-22-23, 22.56.xcarchive" \
  "/Users/vasld/Downloads/PhotosMigrator 2023-3-22, 15-43.crash" \
  "/Users/vasld/Downloads/PhotosMigrator 2023-3-22, 15-43 (Symbolicated).crash" # Optional
```

