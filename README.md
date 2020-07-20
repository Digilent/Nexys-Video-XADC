Nexys Video XADC Demo
==============
  
Description
--------------
This project is a Vivado demo using the Nexys Video's analog-to-digital converter ciruitry, and the OLED display, written in Verilog. When programmed onto the board, voltage levels between 0 and 1 Volt are read off of the JXADC header. The OLED display shows the voltage difference between the appropriate channel's pins in volts. See the Nexys Video's [Reference Manual](https://reference.digilentinc.com/reference/programmable-logic/nexys-video/reference-manual) for more information about how the Artix 7 FPGA's XADC is connected to header JXADC.

| XADC Channel | JXADC Pins              | 
| ------------ | ----------------------- | 
| AD1          | JXADC1(P) / JXADC7(N)   | 
| AD0          | JXADC2(P) / JXADC8(N)   | 
| AD8          | JXADC3(P) / JXADC9(N)   | 
| AD9          | JXADC4(P) / JXADC10(N)  | 
  
Requirements
--------------
* **Nexys Video**: To purchase a Nexys Video, see the [Digilent Store](https://store.digilentinc.com/nexys-video-artix-7-fpga-trainer-board-for-multimedia-applications/)
* **Vivado 2020.1 Installation**: To set up Vivado, see the [Installing Vivado and Digilent Board Files Tutorial](https://reference.digilentinc.com/vivado/installing-vivado/start).
* **MicroUSB Cable**
* **Wires and a Circuit to Measure**

Demo Setup
--------------
1. Download and extract the most recent release ZIP archive from this repository's [Releases Page](https://github.com/Digilent/Nexys-Video-XADC/releases).
2. Open the project in Vivado 2020.1 by double clicking on the included XPR file found at "\<archive extracted location\>/Nexys-Video-XADC/Nexys-Video-XADC.xpr".
3. In the Flow Navigator panel on the left side of the Vivado window, click **Open Hardware Manager**.
4. Plug the Nexys Video into the computer using a MicroUSB cable.
5. In the green bar at the top of the window, click **Open target**. Select "Auto connect" from the drop down menu.
6. In the green bar at the top of the window, click **Program device**.
7. In the Program Device Wizard, enter "\<archive extracted location\>Nexys-Video-XADC/Nexys-Video-XADC.runs/impl_1/top.bit" into the "Bitstream file" field. Then click **Program**.
8. The demo will now be programmed onto the Nexys Video. See the Introduction section of this README for a description of how this demo works.

Next Steps
--------------
This demo can be used as a basis for other projects, either by adding sources included in the demo's release to those projects, or by modifying the sources in the release project.

Check out the Nexys Video's [Resource Center](https://reference.digilentinc.com/reference/programmable-logic/nexys-video/start) to find more documentation, demos, and tutorials.

For technical support or questions, please post on the [Digilent Forum](https://forum.digilentinc.com).

Additional Notes
--------------
For more information on how this project is version controlled, refer to the [Digilent Vivado Scripts Repository](https://github.com/digilent/digilent-vivado-scripts)
<!--- 03/12/2019(ArtVVB): Validated in Hardware in 2018.2 --->