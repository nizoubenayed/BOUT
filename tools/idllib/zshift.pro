; Shift a variable by a given angle in Z
;
; Can be used to shift a variable from (x,y,z) space to (psi,theta,z) space
;
; INPUTS
; 
; var      Can be [x,y,z,t], [x,y,z], [x,z,t] or [x,z]
; zangle   Z shift angle [x] or [x,y]
; 
; OPTIONAL INPUTS
;
; period   Number of periods in a full torus, i.e. fraction of 2pi
; 
; USAGE
;
; To shift a variable var[x,y,z,t] from field-aligned coordinates
; to orthogonal coordinates, read the grid file
;
; var = collect(var="variable")
; g = file_import("grid_file.nc")
; 
; var_shifted = zshift(var, -g.zshift, period=period)
;
; where period is the same as the ZPERIOD setting in the BOUT.inp
; options file. NOTE the minus sign on the shift angle
;
; LIMITATIONS
; 
; Currently uses interpolation to perform shifting. Should change
; to FFTs to be consistent with BOUT++ code
;

FUNCTION zshift, var, zangle, period=period

  IF NOT KEYWORD_SET(period) THEN period = 1.0
  
  s = SIZE(var)
  s2 = SIZE(zangle)

  IF (s[0] EQ 4) AND (s2[0] EQ 2) THEN BEGIN
    ; XYZT var, XY angle
    nt = s[4]
    result = var
    
    ; Shift each time-slice separately
    FOR t=0, nt-1 DO BEGIN
      result[*,*,*,t] = zshift(REFORM(var[*,*,*,t]), zangle, period=period)
    ENDFOR
  ENDIF ELSE IF(s[0] EQ 3) AND (s2[0] EQ 2) THEN BEGIN
    ; XYZ var, XY angle
    
    ny = s[2]
    result = var
    
    ; Shift each y slice separately
    FOR y=0, ny-1 DO BEGIN
      result[*,y,*] = zshift(REFORM(var[*,y,*]), $
                             REFORM(zangle[*,y]), $
                             period=period)
    ENDFOR
  ENDIF ELSE  IF (s[0] EQ 3) AND (s2[0] EQ 1) THEN BEGIN
    ; XZT var, X angle
    
    nt = s[3]
    result = var
    
    ; Shift each time-slice separately
    FOR t=0, nt-1 DO BEGIN
      result[*,*,t] = zshift(REFORM(var[*,*,t]), zangle, period=period)
    ENDFOR
  ENDIF ELSE IF (s[0] EQ 2) AND (s2[0] EQ 1) THEN BEGIN
    ; XZ variable, X angle

    nx = s[1]
    nz = s[2]
    dz = 2.0*!PI / (period * FLOAT(nz-1))
    
    result = FLTARR(nx, nz)
    
    FOR x=0, nx-1 DO BEGIN
      offset = zangle[x] / dz
      
      FOR z=0, nz-1 DO BEGIN
        zpos = (((z + offset) MOD (nz-2)) + (nz-2)) MOD (nz-2)
        
        result[x,z] = INTERPOL(REFORM(var[x,*]), FINDGEN(nz), zpos, /SPLINE)
      ENDFOR
    ENDFOR
  ENDIF ELSE BEGIN
    PRINT, "Don't know what to do"
    result = 0
  ENDELSE
  
  RETURN, result
END
