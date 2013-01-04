#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "RunThroughActive", Category = "Value", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class ValueRunThroughActiveNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Indices")]
		IDiffSpread<int> FInIndices;

		[Input("Projector Resolution")]
		ISpread<int> FInRes;
		
		[Input("Bundle Size", IsSingle=true, DefaultValue=16)]
		IDiffSpread<int> FInBundleSize;
		
		[Input("Reset", IsBang=true, IsSingle=true)]
		ISpread<bool> FInReset;
		
		[Input("Run", DefaultValue=1, IsSingle=true)]
		ISpread<bool> FInRun;
		
		[Input("All In One Frame")]
		IDiffSpread<bool> FInAllAtOnce;

		[Output("Ray X")]
		ISpread<int> FOutRayX;
		
		[Output("Ray Y")]
		ISpread<int> FOutRayY;
		
		[Output("Index")]
		ISpread<int> FOutIndex;
		
		[Output("Render Scene")]
		ISpread<bool> FOutDrawScene;
		
		[Output("Render Rays")]
		ISpread<bool> FOutDrawRays;

		[Import()]
		ILogger FLogger;
		
		int FBundleSize = 16;
		int FCurrentIndex = 0;
		bool FComplete = false;
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			FOutDrawRays[0] = false;
			FOutDrawScene[0] = false;
			
			if (FInReset[0])
			{
				FCurrentIndex = -1;
				FComplete = false;
			}
			
			FOutIndex[0] = FCurrentIndex;
			
			if (FInBundleSize.IsChanged || FInAllAtOnce.IsChanged) {
				FBundleSize = FInBundleSize[0];
				FOutRayX.SliceCount = FBundleSize * FBundleSize;
				FOutRayY.SliceCount = FBundleSize * FBundleSize;
			}
			
			if (FInRun[0])
			{				
				if (!FInAllAtOnce[0])
				{
					if (FCurrentIndex == -1)
					{
						FOutDrawScene[0] = true;
						FOutDrawRays[0] = false;
						FCurrentIndex++;
					}
					else if (FCurrentIndex < FInIndices.SliceCount)
					{
						int OffsetIndex = FInIndices[FCurrentIndex];
						int BundleColumns = FInRes[0] / FBundleSize;
						int OffsetX = (OffsetIndex % BundleColumns) * FBundleSize;
						int OffsetY = (OffsetIndex / BundleColumns) * FBundleSize;
						int SliceIndex = 0;
						
						for (int i = 0; i < FBundleSize; i++)
						{
							for (int j = 0; j < FBundleSize; j++)
							{
								FOutRayX[SliceIndex] = i + OffsetX;
								FOutRayY[SliceIndex] = j + OffsetY;
								SliceIndex++;
							}
						}
						FOutDrawRays[0] = true;
						FCurrentIndex++;
					}
				} else {
					if (!FComplete)
					{
						int RayCount = FBundleSize * FBundleSize * FInIndices.SliceCount;
						FOutRayX.SliceCount = RayCount;
						FOutRayY.SliceCount = RayCount;
						
						int SliceIndex = 0;
						
						for (int idx = 0; idx < FInIndices.SliceCount; idx++)
						{
							int OffsetIndex = FInIndices[idx];
							int BundleColumns = FInRes[0] / FBundleSize;
							int OffsetX = (OffsetIndex % BundleColumns) * FBundleSize;
							int OffsetY = (OffsetIndex / BundleColumns) * FBundleSize;
							
							for (int i = 0; i < FBundleSize; i++)
							{
								for (int j = 0; j < FBundleSize; j++)
								{
									FOutRayX[SliceIndex] = i + OffsetX;
									FOutRayY[SliceIndex] = j + OffsetY;
									SliceIndex++;
								}
							}
						}
						
						FOutDrawRays[0] = true;
						FOutDrawScene[0] = true;
						FComplete = true;
					}
				}
			}
		}
	}
}
