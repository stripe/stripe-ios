//
//  ShopPayStaticHTMLPage.swift
//  StripePaymentSheet
//
//  Created by John Woo on 6/9/25.
//

import UIKit

class ShopPayStaticHTMLPage: NSObject {
    static let htmlString = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <title>iOS WebView Bridge Demo</title>
            <style>
                body {
                    font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
                    margin: 0;
                    padding: 20px;
                    color: #333;
                    max-width: 600px;
                    margin: 0 auto;
                }
                
                h1 {
                    color: #007AFF;
                    font-size: 24px;
                    margin-bottom: 20px;
                }
                
                .card {
                    background: #fff;
                    border-radius: 12px;
                    padding: 16px;
                    margin-bottom: 16px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }
                
                button {
                    background-color: #007AFF;
                    color: white;
                    border: none;
                    padding: 10px 16px;
                    border-radius: 8px;
                    font-size: 16px;
                    margin: 5px 0;
                    cursor: pointer;
                    transition: background-color 0.2s;
                }
                
                button:active {
                    background-color: #0056b3;
                }
                
                button:disabled {
                    background-color: #cccccc;
                }
                
                input, textarea {
                    width: 100%;
                    padding: 8px;
                    margin: 8px 0;
                    border: 1px solid #ccc;
                    border-radius: 4px;
                    box-sizing: border-box;
                    font-size: 16px;
                }
                
                .result {
                    background-color: #f7f7f7;
                    border-radius: 8px;
                    padding: 12px;
                    margin-top: 10px;
                    white-space: pre-wrap;
                    word-break: break-all;
                    font-family: monospace;
                    max-height: 200px;
                    overflow-y: auto;
                }
                
                .status {
                    margin-top: 10px;
                    padding: 10px;
                    border-radius: 6px;
                }
                
                .success {
                    background-color: #e6fff2;
                    border: 1px solid #00cc66;
                    color: #006633;
                }
                
                .error {
                    background-color: #ffe6e6;
                    border: 1px solid #ff6666;
                    color: #990000;
                }
                
                .loader {
                    display: none;
                    width: 20px;
                    height: 20px;
                    border: 3px solid #f3f3f3;
                    border-top: 3px solid #007AFF;
                    border-radius: 50%;
                    margin-left: 10px;
                    animation: spin 1s linear infinite;
                    display: inline-block;
                }
                
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
                
                .hidden {
                    display: none;
                }
            </style>
        </head>
        <body>
            <h1>iOS WebView Bridge Demo</h1>
            
            <div class="card">
                <h2>Bridge Status</h2>
                <div id="bridgeStatus">Waiting for native bridge...</div>
                <button id="pingNative">Ping Native App</button>
                <div id="pingResult" class="result hidden"></div>
            </div>
            
            <div class="card">
                <h2>Device Information</h2>
                <button id="getDeviceInfo">Get Device Info</button>
                <div id="deviceInfoResult" class="result hidden"></div>
            </div>
            
            <div class="card">
                <h2>Store Data</h2>
                <div>
                    <label for="dataKey">Key:</label>
                    <input type="text" id="dataKey" placeholder="storage_key">
                </div>
                <div>
                    <label for="dataValue">Value:</label>
                    <textarea id="dataValue" placeholder="Enter data to store"></textarea>
                </div>
                <button id="storeDataBtn">Store Data</button>
                <div id="storeResult" class="status hidden"></div>
            </div>
            
            <div class="card">
                <h2>Retrieve Data</h2>
                <div>
                    <label for="retrieveKey">Key:</label>
                    <input type="text" id="retrieveKey" placeholder="storage_key">
                </div>
                <button id="retrieveDataBtn">Retrieve Data</button>
                <div id="retrieveResult" class="result hidden"></div>
            </div>
            
            <div class="card">
                <h2>Native Actions</h2>
                <button id="shareBtn">Share This App</button>
                <button id="notifyBtn">Send Notification</button>
                <div id="actionResult" class="status hidden"></div>
            </div>

            <script>
                // Set up the NativeBridge if it hasn't been injected by iOS
                if (!window.NativeBridge) {
                    window.NativeBridge = {
                        _callbacks: {},
                        _callbackId: 0,
                        
                        async callNative(action, payload = {}) {
                            // If we're in development mode on a browser, mock the bridge
        //                            if (!window.webkit || !window.webkit.messageHandlers || !window.webkit.messageHandlers.iosNativeApp) {
        //                                console.log(`Mock native call: ${action}`, payload);
        //                                return this._mockNativeResponse(action, payload);
        //                            }
                            
                            const callbackId = ++this._callbackId;
                            
                            return new Promise((resolve, reject) => {
                                this._callbacks[callbackId] = { resolve, reject };
                                
                                try {
                                    window.webkit.messageHandlers.iosNativeApp.postMessage({
                                        id: callbackId,
                                        action: action,
                                        payload: payload
                                    });
                                } catch (error) {
                                    delete this._callbacks[callbackId];
                                    reject(`Failed to send message to native: ${error}`);
                                }
                                
                                setTimeout(() => {
                                    if (this._callbacks[callbackId]) {
                                        delete this._callbacks[callbackId];
                                        reject('Native call timeout');
                                    }
                                }, 10000);
                            });
                        },
                        
                        _handleNativeResponse(callbackId, error, data) {
                            const callback = this._callbacks[callbackId];
                            if (callback) {
                                if (error) {
                                    callback.reject(error);
                                } else {
                                    callback.resolve(data);
                                }
                                delete this._callbacks[callbackId];
                            }
                        },
                        
                        // Mock responses for development testing in browser
                        _mockNativeResponse(action, payload) {
                            return new Promise((resolve) => {
                                setTimeout(() => {
                                    switch (action) {
                                        case 'ping':
                                            resolve({ status: 'success', message: 'Bridge is working (mock)' });
                                            break;
                                        case 'getDeviceInfo':
                                            resolve({
                                                platform: 'iOS (mock)',
                                                version: '15.0',
                                                model: 'iPhone Mock',
                                                uuid: 'mock-device-id',
                                                appVersion: '1.0.0'
                                            });
                                            break;
                                        case 'storeData':
                                            resolve({ status: 'success', key: payload.key });
                                            break;
                                        case 'retrieveData':
                                            if (payload.key === 'test') {
                                                resolve({ value: 'This is test data from mock bridge' });
                                            } else {
                                                resolve({ value: null });
                                            }
                                            break;
                                        case 'share':
                                            resolve({ shared: true });
                                            break;
                                        case 'notify':
                                            resolve({ scheduled: true });
                                            break;
                                        default:
                                            resolve({ status: 'unknown_action', action });
                                    }
                                }, 300);
                            });
                        }
                    };
                    
                    console.log('Mock bridge initialized for development');
                }
                
                // Wait for the DOM to be fully loaded
                document.addEventListener('DOMContentLoaded', function() {
                    // Update bridge status
                    const bridgeStatus = document.getElementById('bridgeStatus');
                    
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iosNativeApp) {
                        bridgeStatus.textContent = 'Native bridge detected ✅';
                        bridgeStatus.style.color = '#00aa55';
                    } else {
                        bridgeStatus.textContent = 'Running in browser (mock mode) ⚠️';
                        bridgeStatus.style.color = '#aa5500';
                    }
                    
                    // Ping the native app
                    document.getElementById('pingNative').addEventListener('click', async function() {
                        const button = this;
                        const resultDiv = document.getElementById('pingResult');
                        
                        button.disabled = true;
                        button.innerHTML = 'Pinging... <span class="loader"></span>';
                        resultDiv.classList.remove('hidden');
                        resultDiv.textContent = 'Waiting for response...';
                        
                        try {
                            const result = await NativeBridge.callNative('ping', { timestamp: Date.now() });
                            resultDiv.textContent = JSON.stringify(result, null, 2);
                        } catch (error) {
                            resultDiv.textContent = `Error: ${error}`;
                            resultDiv.style.color = 'red';
                        } finally {
                            button.disabled = false;
                            button.textContent = 'Ping Native App';
                        }
                    });
                    
                    // Get device information
                    document.getElementById('getDeviceInfo').addEventListener('click', async function() {
                        const button = this;
                        const resultDiv = document.getElementById('deviceInfoResult');
                        
                        button.disabled = true;
                        button.innerHTML = 'Getting Info... <span class="loader"></span>';
                        resultDiv.classList.remove('hidden');
                        resultDiv.textContent = 'Requesting device info...';
                        
                        try {
                            const deviceInfo = await NativeBridge.callNative('getDeviceInfo');
                            resultDiv.textContent = JSON.stringify(deviceInfo, null, 2);
                        } catch (error) {
                            resultDiv.textContent = `Error: ${error}`;
                            resultDiv.style.color = 'red';
                        } finally {
                            button.disabled = false;
                            button.textContent = 'Get Device Info';
                        }
                    });
                    
                    // Store data
                    document.getElementById('storeDataBtn').addEventListener('click', async function() {
                        const button = this;
                        const keyInput = document.getElementById('dataKey');
                        const valueInput = document.getElementById('dataValue');
                        const resultDiv = document.getElementById('storeResult');
                        
                        const key = keyInput.value.trim();
                        const value = valueInput.value;
                        
                        if (!key) {
                            resultDiv.textContent = 'Please enter a key';
                            resultDiv.className = 'status error';
                            resultDiv.classList.remove('hidden');
                            return;
                        }
                        
                        button.disabled = true;
                        button.innerHTML = 'Storing... <span class="loader"></span>';
                        resultDiv.classList.remove('hidden');
                        resultDiv.textContent = 'Storing data...';
                        resultDiv.className = 'status';
                        
                        try {
                            const result = await NativeBridge.callNative('storeData', {
                                key: key,
                                value: value
                            });
                            
                            resultDiv.textContent = `Data stored successfully with key: ${key}`;
                            resultDiv.className = 'status success';
                        } catch (error) {
                            resultDiv.textContent = `Error: ${error}`;
                            resultDiv.className = 'status error';
                        } finally {
                            button.disabled = false;
                            button.textContent = 'Store Data';
                        }
                    });
                    
                    // Retrieve data
                    document.getElementById('retrieveDataBtn').addEventListener('click', async function() {
                        const button = this;
                        const keyInput = document.getElementById('retrieveKey');
                        const resultDiv = document.getElementById('retrieveResult');
                        
                        const key = keyInput.value.trim();
                        
                        if (!key) {
                            resultDiv.textContent = 'Please enter a key';
                            resultDiv.style.color = 'red';
                            resultDiv.classList.remove('hidden');
                            return;
                        }
                        
                        button.disabled = true;
                        button.innerHTML = 'Retrieving... <span class="loader"></span>';
                        resultDiv.classList.remove('hidden');
                        resultDiv.textContent = 'Retrieving data...';
                        resultDiv.style.color = 'inherit';
                        
                        try {
                            const result = await NativeBridge.callNative('retrieveData', { key: key });
                            
                            if (result.value !== null && result.value !== undefined) {
                                resultDiv.textContent = typeof result.value === 'object' ? 
                                    JSON.stringify(result.value, null, 2) : result.value;
                            } else {
                                resultDiv.textContent = 'No data found for this key';
                            }
                        } catch (error) {
                            resultDiv.textContent = `Error: ${error}`;
                            resultDiv.style.color = 'red';
                        } finally {
                            button.disabled = false;
                            button.textContent = 'Retrieve Data';
                        }
                    });
                    
                    // Share button
                    document.getElementById('shareBtn').addEventListener('click', async function() {
                        const button = this;
                        const resultDiv = document.getElementById('actionResult');
                        
                        button.disabled = true;
                        button.innerHTML = 'Opening... <span class="loader"></span>';
                        
                        try {
                            const result = await NativeBridge.callNative('share', {
                                title: 'Check out this app!',
                                message: 'I found this amazing app with WebView-Native bridge capabilities.'
                            });
                            
                            resultDiv.textContent = result.shared ? 
                                'Share sheet was displayed' : 'Share cancelled';
                            resultDiv.className = 'status success';
                            resultDiv.classList.remove('hidden');
                        } catch (error) {
                            resultDiv.textContent = `Error: ${error}`;
                            resultDiv.className = 'status error';
                            resultDiv.classList.remove('hidden');
                        } finally {
                            button.disabled = false;
                            button.textContent = 'Share This App';
                            
                            // Hide result after 3 seconds
                            setTimeout(() => {
                                resultDiv.classList.add('hidden');
                            }, 3000);
                        }
                    });
                    
                    // Send notification
                    document.getElementById('notifyBtn').addEventListener('click', async function() {
                        const button = this;
                        const resultDiv = document.getElementById('actionResult');
                        
                        button.disabled = true;
                        button.innerHTML = 'Sending... <span class="loader"></span>';
                        
                        try {
                           const result = await NativeBridge.callNative('notify', {
                               title: 'WebView Demo',
                               message: 'This notification was triggered from WebView!',
                               delay: 5 // seconds from now
                           });
                           
                           resultDiv.textContent = result.scheduled ? 
                               'Notification scheduled in 5 seconds' : 'Failed to schedule notification';
                           resultDiv.className = 'status success';
                           resultDiv.classList.remove('hidden');
                       } catch (error) {
                           resultDiv.textContent = `Error: ${error}`;
                           resultDiv.className = 'status error';
                           resultDiv.classList.remove('hidden');
                       } finally {
                           button.disabled = false;
                           button.textContent = 'Send Notification';
                           
                           // Hide result after 3 seconds
                           setTimeout(() => {
                               resultDiv.classList.add('hidden');
                           }, 3000);
                       }
                   });
                   
                   // Let the native app know the web content is fully loaded
                   if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iosNativeApp) {
                       try {
                           NativeBridge.callNative('webviewReady', {
                               timestamp: Date.now(),
                               path: window.location.pathname
                           }).then(response => {
                               console.log('Native app acknowledged ready state:', response);
                           }).catch(error => {
                               console.error('Error notifying ready state:', error);
                           });
                       } catch (e) {
                           console.error('Failed to notify ready state:', e);
                       }
                   }
               });
               
               // Handle messages from native code (can be used for push events)
               window.handleNativeEvent = function(eventName, data) {
                   console.log(`Native event received: ${eventName}`, data);
                   
                   // Example: Handle different event types
                   switch(eventName) {
                       case 'newData':
                           // Show notification about new data
                           showToast(`New data available: ${data.description}`);
                           break;
                           
                       case 'connectionChanged':
                           // Handle connection state change
                           if (data.isConnected) {
                               showToast('Internet connection restored');
                           } else {
                               showToast('Internet connection lost', 'warning');
                           }
                           break;
                           
                       case 'appWillEnterForeground':
                           // App is coming back to foreground
                           refreshData();
                           break;
                   }
               };
               
               // Helper function to show toast messages
               function showToast(message, type = 'info') {
                   // Create toast container if it doesn't exist
                   let toastContainer = document.getElementById('toast-container');
                   if (!toastContainer) {
                       toastContainer = document.createElement('div');
                       toastContainer.id = 'toast-container';
                       toastContainer.style.position = 'fixed';
                       toastContainer.style.bottom = '20px';
                       toastContainer.style.left = '50%';
                       toastContainer.style.transform = 'translateX(-50%)';
                       toastContainer.style.zIndex = '1000';
                       document.body.appendChild(toastContainer);
                   }
                   
                   // Create toast element
                   const toast = document.createElement('div');
                   toast.style.backgroundColor = type === 'warning' ? '#ff9800' : '#333';
                   toast.style.color = '#fff';
                   toast.style.padding = '12px 24px';
                   toast.style.borderRadius = '8px';
                   toast.style.marginTop = '10px';
                   toast.style.boxShadow = '0 3px 10px rgba(0,0,0,0.2)';
                   toast.style.fontWeight = '500';
                   toast.style.opacity = '0';
                   toast.style.transition = 'opacity 0.3s ease-in-out';
                   toast.textContent = message;
                   
                   // Add to container and animate in
                   toastContainer.appendChild(toast);
                   setTimeout(() => {
                       toast.style.opacity = '1';
                   }, 10);
                   
                   // Remove after timeout
                   setTimeout(() => {
                       toast.style.opacity = '0';
                       setTimeout(() => {
                           toast.remove();
                       }, 300);
                   }, 3000);
               }
               
               // Example function to refresh data
               function refreshData() {
                   console.log('Refreshing data...');
                   // Implementation would depend on your app's needs
               }
               
               // Notify native app when the page is being unloaded
               window.addEventListener('beforeunload', function() {
                   if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.iosNativeApp) {
                       try {
                           // Use sync method as async would be cancelled during unload
                           window.webkit.messageHandlers.iosNativeApp.postMessage({
                               action: 'webviewUnloading',
                               payload: { timestamp: Date.now() }
                           });
                       } catch (e) {
                           console.error('Failed to notify unload state:', e);
                       }
                   }
               });
           </script>
        </body>
        </html>
        """
}
