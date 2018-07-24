/*
  This program get course infomation from cbr.ru - swiss franc, yen
  and put in the cluster table with the details by day.
*/
DECLARE
  vcnf integer:=0;
  vjpy integer:=0;
  vfc_id   char(3);
  vfn_val1 number(13,2);
  vfn_val2 number(13,2);
  req     utl_http.req;
  resp    utl_http.resp;
  name    VARCHAR2(1024);
  value   VARCHAR2(1024);
  vpos    integer;
  vfl     integer;
  vstr    varchar2(30000);
  vfld    varchar2(30000);
  html     CLOB;
BEGIN
  req := utl_http.begin_request ('http://cbr.ru/currency_base/daily/?date_req=18.07.2018');
  resp := utl_http.get_response(req);

 /* dbms_output.put_line('HTTP response status code:
 ' || resp.status_code);
  dbms_output.put_line('HTTP response reason: '
 || resp.reason_phrase);*/


  FOR i IN 1 .. utl_http.get_header_count(resp) 
  LOOP
    utl_http.get_header(resp, i, name, value);
  END LOOP;

  LOOP
    utl_http.read_line(resp, value, TRUE);
    
    if ((html is not null) or (value='<table class="data">')) then
      html := html || value;
      dbms_output.put_line(value);
    end if;
    
    if value='</table>' then
      exit;
    end if;
    
  END LOOP;
  
  vpos := instr(html,'<tr>');
  html := substr(html,vpos);
  
  html := replace(html,'<th>','<td>');  
  html := replace(html,'</th>','</td>');
  
  html := replace(html,'<tbody>','');
  html := replace(html,'</tbody>','');
  html := replace(html,'</table>','');
  html := replace(html,'</body>','');
  html := replace(html,'</table>','');
  html := replace(html,'</tr>','');
  html := replace(html,'<tr>','###');
 
  for recs in 
    ( SELECT regexp_substr(str, '[^###]+', 1, level) str
    FROM (
          SELECT html str FROM dual     ) t
    CONNECT BY instr(str, '###', 1, level - 1) > 0 ) 
  loop
    vstr := replace(recs.str,'</td>','');
    vstr := replace(vstr,'<td>','###');
    vpos:=0;
    vfl:=0;
 --   dbms_output.put_line('#line - '||vstr||'#');
    if length(vstr)<10 then exit; end if;
    
    for recs1 in 
      ( SELECT regexp_substr(str, '[^###]+', 1, level) str
      FROM (
            SELECT vstr str FROM dual     ) t
      CONNECT BY instr(str, '###', 1, level - 1) > 0 ) 
    loop
      vpos:=vpos+1;
      vfld:=recs1.str;
      vfld := replace(vfld,chr(13));
      vfld:=trim(replace(vfld,chr(10)));
      
      if ((vpos=3) and (vfld in ('CHF','JPY') ))
      then
        vfl:=1;
        vfc_id:=vfld;
        if (vfld in ('CHF')) then
          vcnf := 1;
        end if;
        if (vfld in ('JPY')) then
          vjpy := 1;
        end if;
      end if;
      if ((vfl=1) and (vpos=4) and (vcnf+vjpy=1)) 
      then
        begin
          if vfld='' then vfld:='0'; end if;
          vfn_val1:=to_number(vfld,'9999999999,9999999');
        exception when others then
          dbms_output.put_line('error - '||vfld);
        end;
      end if; 
      if ((vfl=1) and (vpos=6) and (vcnf+vjpy=1)) 
      then
        begin
          if vfld='' then vfld:='0'; end if;
          vfn_val2:=to_number(vfld,'9999999999,9999999');
        exception when others then
          dbms_output.put_line('error - '||vfld);
        end;
      end if; 
       if ((vfl=1) and (vpos in ( 3, 4, 6 )) and (vfc_id is not null) and (vfn_val1 is not null) and (vfn_val2 is not null))
      then  
      null;
     --  dbms_output.put_line( ' vfc_id = ' || vfc_id ||' vfn_val1 = '||to_char(vfn_val1,'9999999999.99999')||' vfn_val2 = '||to_char(vfn_val2,'9999999999.99999') );
        delete from my_table where fd_date=to_date('19.07.2018','dd.mm.yyyy') and fc_id=vfc_id;
        
        insert into my_table
        (
          fd_date,
          fc_id  ,
          fn_val1 ,
          fn_val2 
        )
        values
        ( to_date('19.07.2018','dd.mm.yyyy'),
          vfc_id  ,
          vfn_val1 ,
          vfn_val2 
        );
        commit;

      end if;
      if vcnf+vjpy=2 then
        exit;
      end if;
    end loop;
    
  end loop;

EXCEPTION
  WHEN utl_http.end_of_body THEN
 utl_http.end_response(resp);
END;
/
